---
layout: page
title: About this site
permalink: /about/
---

This site was updated <span id="buildtimestamp">{{ site.time }}</span>. It is hosted on [GitHub Pages](https://pages.github.com), which is an absolutely free static page hosting service. That also means source code to this site is on [GitHub]({{ site.origin }}).

GitHub Pages, and by extension this site, utilize the amazing [Jekyll static site generator](https://jekyllrb.com/). According to its [Wikipedia article](https://en.wikipedia.org/wiki/Jekyll_%28software%29), it is the most popular static site generator, and for good reason.

This site is being rendered using [a fork](https://github.com/ironiridis/minima) of the theme called minima. This fork takes [the 2.5.1 release](https://github.com/jekyll/minima/releases/tag/v2.5.1) and cherry-picks [two](https://github.com/jekyll/minima/pull/433) [modifications](https://github.com/jekyll/minima/pull/468) from upstream that allow additional directives in the page &lt;head&gt; tag. With this, I added [favicon](https://en.wikipedia.org/wiki/Favicon) resources from [favicon.io](https://favicon.io/emoji-favicons/necktie/). It also cherry-picks [my own PR](https://github.com/jekyll/minima/pull/650) to support the Mastodon `rel="me"` link verification attribute.

This site does not use any sort of tracking software, including cookies, nor does it feature any advertising or analytics, and it doesn't load any third-party content via CDN. There is no privacy policy, license, or warranty. All content (unless otherwise stated) is protected by United States copyright law, so please refrain from duplicating the content of this website.

<script>
function buildtimereplace() {
    try {
        n = document.getElementById('buildtimestamp');
        m = moment(n.innerText, "YYYY-MM-DD HH:mm:ss Z");
        if (!m.isValid()) {
            console.log("Moment.js does not think", n.innerText, "is valid, leaving as-is")
            return;
        }
        n.innerText = m.format('LLL') + ', ' + m.fromNow();
    } catch(e) {
        console.log("Replacing build timestamp threw",e)
        return
    }
}
</script>
<script src="/assets/moment-2.27.0.min.js" integrity="sha256-ZsWP0vT+akWmvEMkNYgZrPHKU9Ke8nYBPC3dqONp1mY=" async="async" defer="defer" onload="buildtimereplace()"></script>
