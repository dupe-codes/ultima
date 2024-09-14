# off on a coding adventure

@July 26 2023

In just two weeks, I'll be in the middle of my first week at the [Recurse Center](https://www.recurse.com), participating in a three-month programming retreat with the singular focus of learning for its own sake. The Recurse Center provides a space and community for motivated programmers to study, work, code, and grow without an enforced curriculum. All it asks of its participants is to be wholly present and to learn generously, requests that I am eager to satisfy.

In many ways, this post is an exciting followup to my writeup on leaving Princeton ([[1 - in-n-out, my brief stint at princeton]]), in which I described the reasons for my early departure from its CS Master's program. If I were to select any of the reasons listed there as the _primary_, it would be the realization that my participation in the program was motivated by my coveting an externally validated status symbol (a degree from such a prestigious institution) rather than any intrinsic excitement or passion for the field of study. I also briefly described how I'd started a new software engineering role since my departure and that it helped me rediscover some of my original passion for the field. At the very least, it had laid down the initial kindling needed to relight it. 

That passion has since fully reignited (maybe blazing out of control, to the detriment of my other hobbies). I've spent the better part of the last nine months immersed in technical studies, diving deep into topics of distributed systems, low-level programming, AI/ML fundamentals, programming languages, and foundational math (linear algebra, calculus, and the like). It has been a period of the most dedicated technical learning I've engaged in since my time at Stanford. Even more dedicated than my semester in grad school! 

And that brings us to my choice to join the Recurse Center. Before the retreat begins, I want to articulate my motivations for participating, a tentative outline of how I plan to spend my time there, and an overview of how I'll keep myself accountable for hitting my learning objectives. 

## motivations

I first learned of RC's existence around the end of January, a few months into my self-study renaissance, after stumbling upon [Julia Evans's writing on how she'd spent her time there.](https://jvns.ca/blog/2017/09/17/how-i-spent-my-time-at-the-recurse-center/) Her description of the program's goals painted it as an environment perfectly designed for the learning I craved. I was already dedicating my evenings and large chunks of my weekends to working through a curriculum entirely of my creation. Crucially, the contents of that curriculum were wholly based on my interests, not on external factors like improving my employability or attaining a degree. Any efforts to expand my fundamental understanding of computing would pay dividends for my software engineering skills, but learning how to formulate [the maximum flow problem as a linear program](http://www.cs.cmu.edu/~odonnell/toolkit13/lecture14.pdf) wasn't likely to provide immediate value to my day job. A retreat, then, that offered a shared community that highlights growing your ability to make learning decisions based on curiosity rather than external pressures (what RC calls "building your volitional muscles") as one of its core principles was immediately appealing. I decided to bookmark a link to the RC website to revisit if my study efforts weren't short-lived.

Fast-forward to this summer, and those ambitions had proven anything but fickle. My study routine had become second nature, and I felt genuinely happy when I imagined my life now and into the foreseeable future as one oriented around learning once again. However, I felt continuously limited by how little meaningful time I had to study. I also knew I was missing out on the sort of force-multiplying benefits learning alongside similarly motivated peers could provide. 

The answer to my troubles felt clear. I revisited the bookmarked Recurse Center website and resolved to apply. I was thankfully admitted after an interview process that proved quite enjoyable. Then, my work graciously arranged a leave of absence, allowing me to participate in the Fall 1 retreat batch. Suddenly, what at the start of the year had been something that "seemed cool to do someday" had now become something cool that I am imminently doing.

To summarize, I'm attending RC to spend three months focused solely on exploring my intellectual curiosities, immersed in a community full of peers doing the same.

## goals & ambitions

My current intentions for my studies are to make as much progress as possible across a wide breadth of my technical interests. I'm in the "explore" phase of an "explore, exploit" oriented approach to learning. My interests have always been broad, but due to an (again externally) imposed sense of maximizing career impact, I've always felt pressured to "pick a lane" and stick to it. Now, I want to satiate my curiosity across the broad spectrum of work computer science encompasses before diving deep into a chosen sub-field or track of concentrated study. That desire to ultimately enter an "exploit" procedure, dedicating myself to a particular problem domain, is motivated by the fact that I want to return to graduate studies and academia at some point. But, I'm now in no rush to get there, a nice change from the nervous energy with which I approached most of my plans earlier in life. Even when I do choose a particular domain, I'll do so knowing that I need to dedicate at least a portion of my studies to continued explorations outside of it; i.e., I hope to find the problem space to commit _most_ of my time to but know that I am at my happiest when I don't dedicate _all_ of my time to one thing and can nurture other parts of myself.

Enough with the high level. Concretely, here are the areas I'd like to explore in the coming months.

### 1. low-level systems programming

I've been recently working through the content of [MIT's Operating Systems Engineering course](https://pdos.csail.mit.edu/6.828/2022/schedule.html) and reading the [OSTEP textbook](https://pages.cs.wisc.edu/~remzi/OSTEP/) to solidify my understanding of operating systems and to get my feet wet with lower-level programming. I want to continue these efforts while at RC, focused on implementing concrete projects like building a toy operating system (maybe my own [xv6](https://pdos.csail.mit.edu/6.828/2012/xv6.html) from scratch) and systems components like a heap allocator. I'm primarily motivated here because the software engineering opportunities that currently look most compelling to me lie in deep systems programming domains; e.g., I would jump at the chance to work in the depths of databases at [TigerBeetle](https://tigerbeetle.com/) or compute engines for AI workloads at [Modular](https://www.modular.com/).

### 2. programming languages and compilers

In college, the programming experience that convinced me to major in Computer Science was implementing a BASIC interpreter for my second-quarter introductory CS course. By some cruel twist of fate and/or poor planning, I never moved on to take Stanford's compilers or programming language design courses. Now, I'd like to experience the excitement I felt as a burgeoning Freshman CS major implementing BASIC language features far beyond the assignment requirements at three a.m. I plan to read Robert Nystrom's [Crafting Interpreters](https://craftinginterpreters.com/) and Thorsten Ball's [Building a Compiler/Interpreter in Go](https://interpreterbook.com/), build out a small compiler for a toy domain-specific language (maybe a baby [Mojo](https://www.modular.com/mojo)?), and dedicate time to learning more general programming languages (Rust and OCaml are top of my list).

### 3. formal methods & proof assistants
   
I'm particularly excited to dive into this problem space. I'm motivated to explore ideas around certifiably correct programs for two reasons. 
	
First, I believe there will be a growing need for strong guarantees of program correctness as more code is produced through AI-assisted tools (if not made entirely by AI agents alone). Acquiring knowledge on tools for verifying program correctness is thus an application of that good old phrase that goes something like "When there's a gold rush, sell shovels." Or, maybe more apt, something like "When there's a bug infestation, sell bug spray?" We might enter an exciting world in the near term where the ability to write code isn't a bottleneck to solving tricky problems. Still, I cry inside when I imagine how confusing the bugs will be when they originate in code we haven't even written ourselves. (And there _will_ be many, many bugs. After all, I'm sure some of MY Github-hosted code has made its way into LLM training sets!) 

Second, the tools themselves look really, _really_ incredible. The snippets of code I've read from proof assistants like Coq and Dafny contain within them a real sense of beauty in their intermixing of executable procedures alongside theorems and mathematical definitions. And I'm intensely curious about what applications lie in wait for machine learning systems applied to this area. The common thread through all these thoughts is simply the happy marriage of math and computing and a single question I've been chewing on: How much can we accelerate research into the mathematical underpinnings of our universe with more capable tools?
	
While at RC, I want to focus my formal methods explorations on learning broadly what the work looks like (there's an excellent chance I fundamentally misunderstand the goals and actual nature of the field!) by reading current research publications, studying introductory texts like the freely available [Software Foundations](https://softwarefoundations.cis.upenn.edu/), and gaining some direct experience working with the Coq proof assistant via [Certified Programming with Dependent Types](http://adam.chlipala.net/cpdt/).   

### 4. math foundations

This is a natural companion to my other interests and an area I've already dedicated substantial time to studying. Late last year, I accepted the uncomfortable conclusion that I had spent the better part of a decade fumbling around with fundamental gaps in my math knowledge. For example, I never took a linear algebra course at Stanford; instead, I took classes on vector calculus and ordinary differential equations (emphasizing engineering applications) to satisfy my degree requirements. And.. that's it. I took no more math courses, thus rendering all subsequent mathematical concepts and understanding I did pick up through the rest of my studies as a detour or add-on towards completing some other work; e.g., I guess I somewhat came to understand the _intuition_ behind eigenvalues to _vaguely_ grasp the high-level concepts of spectral graph theory when it was presented in an advanced algorithms course. But if you'd asked me before this year what a vector space _really_ was, I would have shrugged and asked to talk about something else. 

Those gaps within a subject I have always loved didn't sit right with me. So, I set out this year to start filling them. I want to continue those efforts while at RC, wrapping up my focus on linear algebra and moving on to topics in abstract algebra, discrete mathematics, and calculus.

### additional goals

I'll end this section with a list of additional goals I'd like to accomplish outside of the focuses above:

1. I'd like to cultivate a _coding habit_, i.e., the ability to seamlessly dive into writing code daily without hesitation. This is important because applying what I learn in concrete coding projects vastly strengthens my understanding.
   
2. I want to improve my command over Vim motions and the other elements of my development toolbox, e.g., tmux, git, and Unix shell commands like grep, find, parallel, etc.

3. I'd like to occasionally stream my development efforts on Twitch. The developer community there seems lovely. I'd love to contribute and open myself up to even more opportunities to meet folks excited by the same stuff as me. 

## accountability

My accountability plans are simple: my declared intentions - of subjects to study, projects to build, and work to do - will be made publicly, here in writing, shared online and among my peers at RC. This post and its outline of my ambitions is the first step!

A crucial component of accountability is the measure by which success will be defined. To reiterate, I am optimizing for a breadth of study here. I will consider my efforts successful if I come out the other side with completed projects (big or small) and readings in each of my focus areas, with some heavier weight applied to my efforts in my math and programming language/compiler studies. That said, I also want to maintain openness to seeing where the tides of RC take me. It's important to me personally and as a member of the RC community that I spend ample time learning about what others are working on and contributing to their efforts in any way I can!

## closing remarks

This has gotten longer than I originally intended. I've struggled to contain my excitement and have droned on and on about my plans. I'll end the rambling and dedicate future writing to deeper dives into my focus areas. 

This year has been transformational for me, marked by a transition from time spent considering all the paths my life could take to time spent confident in the one I chose. I'm now building out the life I want to live over the next decade, and RC is a giant leap forward on that journey. 
