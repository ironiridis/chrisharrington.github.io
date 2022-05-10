---
layout: post
title: "Creating a DNS-based URL Shortener [Part 1]"
categories: project urlshorten
tags: aws route53 lambda go
---
It's 2022, and nobody wants to use URL shorteners anymore. They are [user-hostile](https://en.wikipedia.org/wiki/URL_shortening#Privacy_and_security), harmful to [the health of the open internet](https://en.wikipedia.org/wiki/Link_rot), and [virtually unnecessary](https://en.wikipedia.org/wiki/t.co). So let's make one.

To avoid an aphorism, there are a lot of ways to accomplish this task. I wanted to play around with AWS Route 53 a bit, so that's where I started when I wrote [the code](https://github.com/ironiridis/drin) we'll discuss.

## What we'll use
* Go 1.18+
* AWS
    * ACM
    * API Gateway
    * Graviton2
    * Lambda
    * Route 53
* DNS
    * You should have tools like `dig` available
    * You can alternately use [mxtoolbox](https://mxtoolbox.com/SuperTool.aspx)
* Your domain, if you have one
    * In this post I'll refer to it as `example.com`
    * If you don't have a domain connected to Route 53, you can buy one

## Set up the AWS Services
Part 1 of this series will be configuring your AWS account. If you already know your way around AWS, you can probably skip it, but this part will cover every AWS step needed to get working.

### Making sure Route 53 and your domain agree
First, you'll want to have your `example.com` domain pointed at your Route 53 hosted zone name servers. When you run `dig -t ns example.com` you should get a set of records that look the same (though not necessarily in the same order) as the NS record in your hosted zone. If it doesn't look right, then you likely need to configure the authoritative nameservers with your domain registrar.

Now if you don't have a domain, it turns out you can just buy one through Amazon's [Route 53 Domains](https://us-east-1.console.aws.amazon.com/route53/home#DomainListing:). As of this writing, `.link` domains are $5 USD, and `.click` domains are $3 USD. Be the owner of `risky.click` for three bucks! Or don't, it's apparently already taken. Anyway, when you buy a domain through AWS, the console will automatically create a Route 53 hosted zone for it, skipping some faffing around.

### Requesting an ACM certificate
AWS offers free SSL certificates for services running on their platform. We'll need one, since it isn't 1997 anymore. Request one from [ACM in us-east-1](https://us-east-1.console.aws.amazon.com/acm/home?region=us-east-1#/welcome):
* Click "Request".
* Select (or leave selected) "Request a public certificate" and click "Next".
* Under "Fully qualified domain name", you'll put `*.example.com` -- again, substituting your real domain here.
* Choose `DNS validation` -- Route 53 will make this seamless for you -- then click "Request".
* You may not be able to choose your pending certificate yet, if not, refresh or visit the [certificate list](https://us-east-1.console.aws.amazon.com/acm/home?region=us-east-1#/certificates/list) again.
* Assuming the certificate is indeed "Pending validation", you should be able to click "Create records in Route 53".
* You should see a summary of the records that will be created on your behalf, click "Create records".
* In a minute or two, you should be able to refresh your pending certificate and see it is now Issued.

### Creating your API Gateway API
Once your certificate is issued, go visit [API Gateway in us-east-1](https://us-east-1.console.aws.amazon.com/apigateway/main/apis?region=us-east-1&apiId=unselected).
* Click "Create API", then click "Build" under HTTP API.
* Under Integrations, skip the "Add integration" button. We'll do that in a minute.
* Invent a name that's meaningful to you. We'll pretend you wrote `shorturl`.
* Click "Review and Create" and then "Create".
* You should be looking at your API. (If not, go back to [the API list](https://us-east-1.console.aws.amazon.com/apigateway/main/apis?region=us-east-1&apiId=unselected) and click on it.) On the left edge, click "Custom domain names", then click "Create".
* You need a domain name for your shortener. I suggest creating a subdomain for this app, like `short.example.com`.
* Under ACM certificate, you're going to select the certificate we requested earlier. It should look like `*.example.com`.
* Click "Create domain name". You should be looking at your custom domain name now. Click "API mappings" then "Configure API mappings".
* Click "Add new mapping". Under API, select your API, the one we're pretending you called `shorturl`. Under stage, select `$default`. Click "Save".

### Creating the Route 53 Alias
Now that you have created an API Gateway API with a custom domain, we can create a record in Route 53 to connect that together.
* In your hosted zone, click "Create record". If you see a link that says "Switch to quick create", click that.
* Under Record name, type just the subdomain part of your domain. So if your domain is `short.example.com`, type `short`.
* Under Record type, `A` should already be selected. If it isn't, select it.
* Next to Value, turn on the toggle switch for `Alias`. This section will then read "Route traffic to".
* Under Route traffic to, choose `Alias to API Gateway API`.
* In the next dropdown that appears, you'll choose the `us-east-1` region, labelled "US East (N. Virginia)".
* In the next dropdown that appears, clicking inside should reveal the API you created above. (It may just be a hostname, not the name you gave it.) If nothing appears, you either have the wrong name under "Record name" or you have the wrong name in your API Gateway Custom domain. These must match. Once you do see your API, select it.
* You can leave everything else as is and click "Create records".

At this point, you should be able to open your web browser and go to your domain `short.example.com`. We're expecting to see `{"message":"Not Found"}`, which is perfect, because API Gateway is responding to our request, but there's no route yet defined that matches. If that's the result you get, you've done everything correctly up to this step.

### Creating the Lambda function
At the heart of this very silly app is a Lambda function. It is invoked by API Gateway and updates Route 53 in order to service requests. You'll want to head to [the us-east-1 Lambda page](https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions).
* Click "Create function". Leave "Author from scratch" selected.
* Under Function name, provide a name for your function. It isn't important, we'll pretend you called it `shorturlfunc`.
* Under Runtime, scroll down to and select `Provide your own bootstrap on Amazon Linux 2`
* Under Architecture, select `arm64`. This enables the AWS Graviton2 architecture, which is purely optional, but fun.
* The remaining options are fine if left alone, go ahead and click "Create function".

### Connecting it to API Gateway
Head back to [API Gateway in us-east-1](https://us-east-1.console.aws.amazon.com/apigateway/main/apis?region=us-east-1&apiId=unselected), and select the API you created. It's time to connect your Lambda function to the internet.
* Expand the "Develop" section on the left side if necessary, and click "Routes". Then click "Create".
* Under "Route and Method", leave the drop-down set to `ANY`. In the next field, change `/` to `/{x}`. Click "Create".
* You should be back to the Routes view, so click "Create" again.
* This time, change `ANY` to `POST`. Leave `/` as is. Click "Create".
* On the left side, click "Integrations". You should be looking at the Integrations view, and one of your routes should be selected.
* Click "Create and attach an integration".
* Under "Attach this integration to a route", leave the value that's there.
* Under "Integration target", "Integration type", choose `Lambda function`.
* The "AWS Region" should already be `us-east-1`. Under "Lambda function", click inside the field to load functions in that region. You should see the function we created in the last section, and maybe you called it `shorturlfunc`. Select it.
* Skip everything else and click "Create" at the bottom of the page.
* You should be back to the Integrations view, and one of your routes should show "AWS Lambda" on it. Select the other route.
* You should now see a view that offers a choice between creating a new integration or using an existing one. We'll do the latter.
* In the dropdown, you should see an option named like your Lambda function (eg `shorturlfunc`). Select it. Click "Attach integration".

We're pretty close now. Now visiting your domain in a browser should produce `{"message":"Internal Server Error"}`. This doesn't seem like an improvement, but it is; API Gateway is trying to invoke your function, but something goes wrong. In fact, your Lambda function is missing its bootstrap program. That will come in Part 2; for now, we have a couple of small things to do.

### Short detour on Route 53 for the Zone ID
Route 53 creates a unique identifier for your hosted zone, and we're going to need it. It looks like `Z01010101S99Z9ZXZXZX2`, and is available in the "Hosted zone details" section above your zone records. You need this value, so [go get it](https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones#) before we continue.

### Back to Lambda to finish setup
In your Lambda function, we'll need to tell your function which zone we modify to store URLs.
* While looking at the Lambda function, find the tab strip and click "Configuration".
* Under the configuration view, on the left side, find and click "Environment variables".
* In the Environment variables view, click "Edit". Then click "Add environment variable".
* Under "Key", put `ROUTE53_ZONE_ID`. Under "Value", paste your Zone ID we got above. (Don't lose it, we need it for one more thing.)
* Click "Add environment variable" again. Under "Key", put `ROUTE53_RECORD_TTL`. Under "Value", put `1h`.
* Click "Save".
* Back on the page for your function, under the configuration view, on the left side, find and click "Permissions".
* You should see a section titled "Execution role" with a link under "Role name". Click that link, we're headed to IAM.

### Modifying the Lambda role
IAM Roles are short-term assumed identities that are scoped to work with certain services. Lambda uses them in order to grant permissions to functions as they're executing. We'll do that here, by granting your function permission to modify Route 53 records.
* You should be looking at the "Permissions" view. Find and click the button labeled "Add permissions". This will offer two options; click "Create inline policy".
* Welcome to the IAM Policy Visual Editor! Click on "Choose a service" and in the search field that appears, type `53`.
* There are several "Route 53" services, but we specifically want the original. Click the option that reads "Route 53".
* In the search field, type `change`, and check the box next to "ChangeResourceRecordSets".
* Expand the "Resources" section, and click "Add ARN". In the field that appears, paste your Hosted Zone ID. Click "Add".
* Click on "Review policy". For "Name", type `short-url-lambda-modify-route53`. It doesn't have to be exact, but policy names are restricted to letters, numbers, and a handful of symbols -- no spaces.
* Click "Create policy".

And that's it!

## Wrapping up
You've configured all the AWS pieces more-or-less how they need to be configured. The only thing that is missing is the code to run in the Lambda function. In Part 2, we'll check out the code, compile it, and deploy it. Then we'll discuss what it's doing, identify some flaws, and add a feature.