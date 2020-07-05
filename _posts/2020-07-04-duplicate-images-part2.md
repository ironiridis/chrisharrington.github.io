---
layout: post
title: "Detecting duplicate images - Part 2: The naive way"
categories: project dupeimages
tags: graphics go
---
Let's start by defining some data types we can use for output. Go has some great [standard library support for JSON encoding](https://golang.org/pkg/encoding/json/ "encoding/json") which makes this pretty painless, and if we optimize for this encoding, most other encoding packages will be easy to implement.

In order to achieve our goal, the minimum we need to know is:
* What the two images we're comparing are, and
* How different they are.

Let's define a Subject type and a Comparison type.

{% highlight go %}
type Subject struct {
	Filename string
}

type Comparison struct {
	Distance uint
	SubjectA *Subject
	SubjectB *Subject
}
{% endhighlight %}

To start out, we'll assume all `Subject`s are local files. It's useful to abstract this away now at this step, though, since we can keep the notion of a `Subject` later as we add other sources or interfaces.

What does the `Distance` member of `Comparison` mean? How different is a value of `1` versus a value of `65536`? For now, we won't make any concrete assertions, except to say that a larger value indicates a larger difference, and relatively small values indicates "similar". The only value we can define concretely is to say that `0` means "identical".

Of course we will need to track all of our `Subject`s, so let's make a type for that.
{% highlight go %}
type SubjectList struct {
	list []*Subject
}

func NewSubjectList() *SubjectList {
	// Assume for now we'll have the same number of subjects as arguments
	return &SubjectList{list: make([]Subject, 0, flag.NArgs())}
}

func (s *SubjectList) AddFile(path string) error {
	s.list = append(s.list, &Subject{Filename: path})
	return nil
}
{% endhighlight %}

How do we specify `Subject`s? Let's start by passing filenames to an invocation of our program. Once again the standard library makes our lives easier by providing [the flag package](https://golang.org/pkg/flag/ "flag"). Using flag now lets us add command-line options later. Also, for the sake of convenience, let's allow the user to pass in a list of files, or directories, or a combination of both. I like to handle this with [the path/filepath package](https://golang.org/pkg/path/filepath/ "path/filepath").

{% highlight go %}
func main() {
	flag.Parse()
	sl := NewSubjectList()
	for _, fn := range flag.Args() {
		filepath.Walk(fn, sl.filewalkfunc())
	}
}

func (s *SubjectList) filewalkfunc() func(p string, info os.FileInfo, err error) error {
	return func(p string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		return s.AddFile(p)
	}
}
{% endhighlight %}

If `filewalkfunc` looks weird to you, don't worry, it is a little weird. Because `filepath.Walk` expects a function, we need some way to pass our list object along with that function. We could create a global variable and reference it from our function, but some smart Go folks [believe this](https://peter.bourgon.org/blog/2017/06/09/theory-of-modern-go.html "Peter Bourgon's best practices for modern Go") [is harmful](https://dave.cheney.net/2017/06/11/go-without-package-scoped-variables "Dave Cheney's article on avoiding package scoped variables"). Besides, writing tests with globals (Go calls them Package Scoped Variables, because that's precisely what they are) is pretty painful. Anyway, `filewalkfunc` returns [a function that closes around](https://www.calhoun.io/what-is-a-closure/ "Jon Calhoun's article on Go closures") a pointer to our `SubjectList`. That's the call to `s.AddFile`. The outer function definition does look pretty weird, but it makes sense when you remember Go [funcs are a first-class type](https://golang.org/doc/codewalk/functions/ "The Go code walk on functions").

Now that we have gathered up all of our `Subject`s, it's time to actually do something with them. Our strategy for this first (naive!) version will be to iterate through our list and compare each image with every other image. We'll first define the nice abstract way we want this to happen:
{% highlight go %}
func (s *SubjectList) CompareAll() []Comparison {
	// we know that a list of size N will have ((N-1)*N)/2 comparisons. this
	// relationship is the "Triangular numbers"! https://oeis.org/A000217
	r := make([]Comparison, 0, ((len(s.list)-1)*len(s.list))/2)
	for len(s.list) > 0 {
		// take the last subject
		subjecta := s.list[len(s.list)-1]
		// modify the slice to exclude it
		s.list = s.list[:len(s.list)-1]
		// now, compare all the remaining subjects
		for _, subjectb := range s.list {
			r = append(r, subjecta.CompareTo(subjectb))
		}
	}
	return r
}
{% endhighlight %}

In the next article, we will implement `Subject.CompareTo()`. We will need to address two core problems: how we compare two pictures that might not be the same size, and how we quantify the difference between pixels in two images.

>See the complete code for this article [on GitHub](https://github.com/ironiridis/portfolio-examples/tree/386d7b319ba5cf06aac67de0080e7bcaadad0f13).