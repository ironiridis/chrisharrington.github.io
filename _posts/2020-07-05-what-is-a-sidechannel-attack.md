---
layout: post
title: "What is a side-channel attack?"
categories: explainer
tags: security
---
A side-channel attack is a name for a broad class of different security challenges. The [obligatory Wikipedia article](https://en.wikipedia.org/wiki/Side-channel_attack "Wikipedia - Side-channel attack") does a good job of discussing it, especially in a technical sense. Here I'll discuss a contrived example that lays out the concept, but doesn't actually get into computing at all.

<!--- I really wanted to work in "Banking in the 90s" somehow, but 🤷‍♂️ https://www.youtube.com/watch?v=XCiDuy4mrWU -->

## There's Got to Be a Way
<!--- Mariah Carey - https://en.wikipedia.org/wiki/There%27s_Got_to_Be_a_Way -->
Let's invent a scenario: It's the 1990's, and you are a private investigator working for a big bank company. This bank has noticed small sums of cash vanishing from several locations on a predictable schedule, and they suspect some employees are cooperating to smuggle it out of the location. Now, all of the cash disappearing from the vault is treated with a chemical... but there's a problem. All of the employees know that this chemical can be washed off in a typical home clothes washing machine. <!--- I was not aware of the Sonic Youth album at this point in writing this article, but in retrospect during editing, I am very pleased with the coincidence. https://en.wikipedia.org/wiki/Washing_Machine_(album) --> It just takes a particularly heavy duty cycle.

The bank is emphatic that all the employees involved in the heist need to be caught at the same time. That means: no breaking down doors or tense [Law & Order](https://en.wikipedia.org/wiki/Law_%26_Order_%28franchise%29 "dun dun")-style interviews with suspects. We need to detect as many of them as possible without notice. "No problem," you say, "I can detect if they're removing that chemical without ever entering their home, or even looking in a window."

The trick is to measure the consumption of power. There's two means to accomplish this. Assuming the residential power isn't [buried](https://en.wikipedia.org/wiki/Undergrounding), the first method would involve an individual with a cheap ladder, a plausible high-visibility vest, and a [clamp-on ammeter](https://en.wikipedia.org/wiki/Current_clamp). If that's not possible, building-external [electricity meters](https://en.wikipedia.org/wiki/Electricity_meter) can be observed from a distance with a reasonably capable pair of binoculars. Ever noticed that little wheel inside that turns kind of slowly and has the large dark mark on one part? That wheel turning once represents some fixed amount of power consumption. (Well, in the 90's, anyway. Today the purely digital ones are more common, but they have similar indicators.)

## All the Small Things
<!--- Blink-182 - https://en.wikipedia.org/wiki/All_the_Small_Things -->
Homes are full of devices that consume power. Let's take a look at a few classes of power consumers.

### Continuous, unvarying
A lot of power consumption in a typical house is pretty boring. Lights, fans, televisions, these all draw a reasonably consistent amount of power during operation, and many of these are left on for long periods of time. A 60 watt lightbulb (remember those?) will consume that amount of power, ramping up nearly instantly to its peak consumption, and immediately dropping off to zero consumption when it's switched off again.

### Periodic
Now consider a space heater: it will draw a lot of power, with a relatively predictable on/off cycle. If it's rated for 1800 watts, you'd expect an increase of 1800 watts on a power meter for (say) 10 minutes, then a drop of 1800 watts for 2 minutes, then an increase again for 10 minutes, and so on. This ends up being pretty predictable, too.

### Non-periodic
Here's where things get good. A device like a washing machine has varied cycle programs designed to be good for washing clothes. The machine will run several motors on and off with varying speeds, in bursts of different lengths, all with widely different loads. The consumption of the pump motor is different than the consumption of the basket spinning motor at low speed, and that consumption is different still from the basket spinning motor at high speed.

## I Learned from the Best
<!--- Whitney Houston - https://en.wikipedia.org/wiki/I_Learned_from_the_Best -->
To get a good idea of what to look for, you need to take some measurements of your own washing machine. Naturally you will want to load the unit with actual cash to make sure the behavior of your machine is similar to the behavior of the employees you're trying to monitor. Taking detailed recordings of the power consumption of your machine, the important values to record are not the *absolute* amounts, but their relative *scale*. Making sure to measure *only* the consumption of your machine, you can create a sort of power fingerprint for this activity. Ideally, you will want to measure this several times, gathering several samples and seeing if there's variation in your machine. In a perfect world, you might even buy several machines and measure them all, but you will likely find they are all very similar on their most "heavy duty" settings.

## When I Come Around
<!--- Green Day - https://en.wikipedia.org/wiki/When_I_Come_Around -->
Now your task is simple. We know what the consumption pattern of a machine running its heaviest duty cycle looks like. You now task your fleet of interns (oh, uh, let's say you have interns.) to remotely record the power consumption of each suspect house every evening after the bank closes. They gather enough data to plot, minute-by-minute, the consumption pattern of their assigned home.

It's important to capture data even on nights where no cash goes missing. We will want to know if these employees are just always doing lots of laundry. Or if they have some other strange influence on their power usage, which may be due to [other, unrelated activities](https://www.computerworld.com/article/2469854/bitcoin-miners-busted--police-confuse-bitcoin-power-usage-for-pot-farm.html).

Because people use their homes for things other than laundry, the data will be noisy, but that's okay. Remember that the bulk of the things inside a home will either be continuous or periodic; both modify our target's consumption by a relatively fixed, predictable amount. We know if we see consumption jump up by 1000ish watts, we can probably filter that out by looking at the following data just with that as the new "bottom" of our scale. What we're looking for here is jumps up and down in consumption that match our own pattern of measurements, not absolute values.

## We've Got It Goin' On
<!--- Backstreet Boys - https://en.wikipedia.org/wiki/We%27ve_Got_It_Goin%27_On -->
The name of the game at this point is "correlation". We have a pattern of power usage we can look for, we have a set of measurements from homes that may or may not be participating in this heist, we have the schedule where the cash vanishes, and that's all we need for our side-channel attack. Using this information, we can detect with reasonably high probability when a home is doing this particular task of washing the cash, and from there, we can deduce which employees are in on the heist.

Mostly.

Of course part of the problem with a contrived hypothetical scenario is that it deliberately elides inconvenient details.

## I Don't Want to Miss a Thing
<!--- Aerosmith - https://en.wikipedia.org/wiki/I_Don%27t_Want_to_Miss_a_Thing -->
So how inaccurate is our goofy example? Well, if you're talking about attacking a computer CPU, it's not too bad! You can think of the whole home as the CPU itself, and the home appliances & washing machine as representing internal processor structures. Our initial measurement that we did on our own washing machine would be analogous to measuring power usage with our CPU as otherwise idle as possible. Note that while in our example we measure the power consumption of the CPU, there are other things we can measure, such as execution times. There's a surprising amount of information available to gather about the state of a CPU: even the temperature of a certain core can be a kind of data point, as it relates to power consumption and workload.

Of course, washing machines can have a lot of variations, but so do many of the targets of a side-channel attack. Some attacks are highly targeted and limited to a specific environment, but some can be generalized. Some attacks are general enough that they can run inside of a script on a web page, detecting with a reasonable confidence what kind of processor they're running on, and then tuning their attack from there.

However, one thing our scenario ignores is repetition. Most side-channel attacks are, at their core, statistical. This means taking hundreds or thousands of samples, repeating the same task over and over again. Indeed, attacks leveraging [Spectre](https://en.wikipedia.org/wiki/Spectre_%28security_vulnerability%29) generally need to trigger the execution of some code millions of times just to exfiltrate a few hundreds of bytes. And while some side-channel attacks can be totally passive, the majority have some component that can trigger the behavior we want to spy on. For example, if some malware wants to find the encryption key a browser session is using, it may repeatedly trigger a reload of something in that session.

The great thing about statistical analysis is that, with enough of it, you can make other sources of noise in your data invisible. And the great thing about computers is that they can do things over and over really quickly.

>TechRepublic has a pretty [detailed article on Spectre and Meltdown](https://www.techrepublic.com/article/spectre-and-meltdown-explained-a-comprehensive-guide-for-professionals/) that makes for pretty good reading.