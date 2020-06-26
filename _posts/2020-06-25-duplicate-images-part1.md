---
layout: post
title: "Detecting duplicate images - Part 1: Concept"
categories: project dupeimages
tags: graphics go
---
Say you have thousands of image files, and you know at least some of them are highly simliar. It would be handy to be able to find the images that are most similar, and consolidate. How could we approach this problem?

### What we have
For the sake of our discussion, let's say we have 10,000+ JPEG files, all around 16:9 aspect ratio, but of a variety of different sizes. Let's say that these are large enough that we don't want to copy them to our local computer running some desktop photo organizing software, or that we have so many files that such software might be impractical to use. Maybe our files are out in [Amazon S3](https://aws.amazon.com/s3/) or need to be read in over HTTP.

### What we need
Let's say we want to deal with these duplicates or similar images with some business logic, rather than simply deleting them. Ideally, our program should:
* Provide machine-readable output,
* Be able to detect images that are similar but not identical, such as images that were scaled, slightly cropped, watermarked, or edited,
* Provide some kind of "score" through which we can rank similarity, and
* Be as fast, efficient, and accurate as possible.

### Approach
In this series, we will use Go. It has [exhaustive support for S3](https://godoc.org/github.com/aws/aws-sdk-go/service/s3), natural support for multi-core processing, and is a joy to use. In part 2, we will start with a naive comparison approach that fails many of our requirements above. In the following parts, we will refine until we have a reusable tool.
