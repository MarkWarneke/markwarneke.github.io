---
layout: post
title: Blameless Post-Mortems
subtitle:
bigimg:
  - "/img/55QfOLiYqWQ.jpeg": "https://unsplash.com/photos/55QfOLiYqWQ"
image: "/img/55QfOLiYqWQ.jpeg"
share-img: "/img/55QfOLiYqWQ.jpeg"
tags: [Azure DevOps]
comments: true
time: 4
---

What are you going to do after an incident happen? Find the one to blame...? A better idea is to create an environment where failures are accepted and appreciated. You should create an environment of learning and reinforce that failing fast and learning from mistakes is something to strive for.

The described points are mostly based on [the DevOps Handbook](https://www.amazon.de/DevOPS-Handbook-World-Class-Reliability-Organizations/dp/1942788002/ref=sr_1_1?__mk_de_DE=%C3%85M%C3%85%C5%BD%C3%95%C3%91&keywords=The+DevOps+Handbook&qid=1566940325&s=gateway&sr=8-1)

## Introduction

Post-Mortems should help us examine

> mistakes in a way that focuses on the situational aspects of a failure’s mechanism and the decision-making process of individuals proximate to the failure. *by John Allspaw*

Schedule post-mortem as soon as possible after the accident occurs. Links between cause and effect should still be fresh in memory, avoid that these fade or circumstances change.

## Basics of a Post-Mortem

- Construct a detailed incident timeline
- Gather details from many different perspectives
- Ensure **no punishment** of people for making mistakes is happening
- Empower all engineers to feel safe by allowing them to give detailed accounts of their contributions to failures
- Enable and **encourage people who do make mistakes to be the experts**, and who educates the rest of the organization on how to not make them again in the future
- Accept that there is always a discretionary space where humans can decide to take action or not, and that the judgment of those decisions lies in hindsight
- **Propose countermeasures to prevent a similar accident** from happening in the future and ensure these countermeasures are recorded with a target date and an owner for follow-up

## Whom to invite to a Post-Mortem - Stakeholders

Include people to the post mortem who...

- have been involved in decisions that may have contributed to the problem
- identified the problem
- responded to the problem
- diagnosed the problem
- were affected by the problem
- are genuinely interested in attending the meeting to learn

## What ToDos needs to be done for a Post-Mortem Meeting

Engineers should focus on:

> Why did it make sense to me when I took that action?

1. record the timeline of relevant events as they occurred (to best knowledge)
2. what actions have been taken
3. at what time
4. with what effect
5. which investigation pathes have been considered
6. which resolutions steps have been taken

## Post-Mortem Time Schedule

Reserve enough time to find the root cause.
Use the 5-why question method to find it.
Create room to allow brainstorming and to decide on countermeasures to implement.

Counter measures should:

- be prioritized
- assigned to an owner
- have an implementation timeline

Doing this demonstrates that continuos improvement of daily work is more important than doing daily work itself.

## Post-Mortem Documentation

What should be documented to create a good post-mortem and keep track to foster learning. Create an easy to use environment to document! Three key points to document, timeline, meeting details and incident description.

See [Template](#template)

### Incident Timeline

Document when the incident happened and how long it took until the incident was resolved. Also document additional times to be able to measure and create KPIs, e.g. MTTR.

- Incident Start Time
- Incident End Time
- Incident Detect Time
- Additional Times if necessary
  - e.g. First User Impact, First User Report, Hotfix

### Meeting Details

Create basic meeting metadata, like a title, date contact persons etc. 

- Post-Mortem Title
- Post-Mortem Meeting Date
- Post-Mortem Contact Person
- Post-Mortem created by
- Post-Mortem facilitated by

### Incident Description

Describe the incident in short and crisp sentences. Avoid long and detailed descriptions. Add time stamps to make the chronological order clear. Avoid attaching log files or stack traces - be precise.

- Incident Severity
- What happened (Bullet point list with timestamps)
- Additional Info (e.g. images, ! no logs, no stack traces)
- Remediation
  - Bug Tickets associated
- Short Summary
- Tags

## Foster documentation and ease of use

Make it easy to document post-mortems.You can use tools or other easy to use system. The easier the system is, the more people will record and detail the outcomes. It will **enable more organizational learning by creating a good knowledge-base**.

## Things NOT to do

**Don't Blame!**

**Don't punish!**

Avoid using *“would have”* or *“could have”* in statements.
**Be specific**, its not a guessing game or an excuse.
Use terms of the system that actually exists and happened instead.
What did you do or didn't do that lead to the issue.

## Things to do

**Foster Learning!**

## Post-Post-Mortem

After a Post-Mortem we should

- **widely announce** the availability of the meeting notes and any associated artifacts
- place **information on a centralized location** where the entire organization can access it and learn from the incident
- **encourage others** in the organization to read them to increase organizational learning
- **increases transparency with internal and external customers**, which will in turn increases trust

- revisit post-mortems from time to time
- Make sure counter measures are still taking effect and are implemented

## Template

```markdown
# <Title>

| Meeting        | Value          |
| -------------- | -------------- |
| Date           | <Meeting Date> |
| Contact        | <Name>         |
| Created by     | <Name>         |
| Facilitated by | <Name>         |

## Timeline

| Incident    | Value |
| ----------- | ----- |
| Start Time  |       |
| End Time    |       |
| Detect Time |       |
| Additional  |       |

## Description

> Severity: <Severity>

- 


## What happened 
_(Bullet point list with timestamps)_

-

## Additional Info 
_(e.g. images, ! no logs, no stack traces)_

-

## Remediation
-

## Bug Tickets

<Ticket Nr/Link>

## Short Summary

## Tags
```


## Resources

[The DevOps Handbook](https://learning.oreilly.com/library/view/the-devops-handbook/9781457191381/DOHB-ch_19.xhtml)

## Table of content

- [Introduction](#introduction)
- [Basics of a Post-Mortem](#basics-of-a-post-mortem)
- [Whom to invite to a Post-Mortem - Stakeholders](#whom-to-invite-to-a-post-mortem---stakeholders)
- [What ToDos needs to be done for a Post-Mortem Meeting](#what-todos-needs-to-be-done-for-a-post-mortem-meeting)
- [Post-Mortem Time Schedule](#post-mortem-time-schedule)
- [Post-Mortem Documentation](#post-mortem-documentation)
  - [Incident Timeline](#incident-timeline)
  - [Meeting Details](#meeting-details)
  - [Incident Description](#incident-description)
- [Foster documentation and ease of use](#foster-documentation-and-ease-of-use)
- [Things NOT to do](#things-not-to-do)
- [Things to do](#things-to-do)
- [Post-Post-Mortem](#post-post-mortem)
- [Template](#template)
- [Resources](#resources)
- [Table of content](#table-of-content)