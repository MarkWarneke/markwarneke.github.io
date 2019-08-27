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

These Details are mostly by [the DevOps Handbook](https://www.amazon.de/DevOPS-Handbook-World-Class-Reliability-Organizations/dp/1942788002/ref=sr_1_1?__mk_de_DE=%C3%85M%C3%85%C5%BD%C3%95%C3%91&keywords=The+DevOps+Handbook&qid=1566940325&s=gateway&sr=8-1)

## Introduction

Post-Mortems should help us examine

> mistakes in a way that focuses on the situational aspects of a failure’s mechanism and the decision-making process of individuals proximate to the failure. *by John Allspaw*

Schedule post-mortem as soon as possible after the accident occurs. Links between cause and effect should still be fresh in memory, avoid that these fade or circumstances change.

## Environment

- Construct a detailed timeline
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

## Post-Mortem Time

Reserve enough time to find the root cause.
Use the 5-why question method to find it.
Create room to allow brainstorming and to decide on countermeasures to implement.

Counter measures should:

- be prioritized
- assigned to an owner
- have an implementation timeline

Doing this demonstrates that continuos improvement of daily work is more important than doing daily work itself.

## Documentation

What should be documented to create a good post-mortem and keep track to foster learning.

### Incident Timeline

- Incident Start Time
- Incident End Time
- Incident Detect Time
- Additional Times if necessary
  - e.g. First User Impact, First User Report, Hotfix

### Meeting Details

- Post-Mortem Title
- Post-Mortem Meeting Date
- Post-Mortem Contact Person
- Post-Mortem created by
- Post-Mortem facilitated by

### Incident Description

- Incident Severity
- What happened (Bullet point list with timestamps)
- Additional Info (e.g. images, ! no logs, no stack traces)
- Remediation
  - Bug Tickets associated
- Short Summary
- Tags

## Foster documentation and eas of use

Make it easy to document post-mortems (e.g. through tools). The easier it is, the more people will record and detail the outcomes of post-mortems. It will enable more organizational learning through a joined effort.

## Things to not do

**Don't Blame!**

**Don't punish!**

Avoid using “would have” or “could have” in statements.
Be specific, its not a guessing game.
Instead use terms of the system that actually exists and happened.
What did you do or didn't do that lead to the issue.

### Things to do

**Foster Learning!**

## Post-Post-Mortem

After a Post-Mortem we should

- **widely announce** the availability of the meeting notes and any associated artifacts
- place **information on a centralized location** where the entire organization can access it and learn from the incident
- **encourage others** in the organization to read them to increase organizational learning
- **increases transparency with internal and external customers**, which will in turn increases trust

## Resources

[The DevOps Handbook](https://learning.oreilly.com/library/view/the-devops-handbook/9781457191381/DOHB-ch_19.xhtml)

## Table of content

- [Introduction](#introduction)
- [Environment](#environment)
- [Whom to invite to a Post-Mortem - Stakeholders](#whom-to-invite-to-a-post-mortem---stakeholders)
- [What ToDos needs to be done for a Post-Mortem Meeting](#what-todos-needs-to-be-done-for-a-post-mortem-meeting)
- [Post-Mortem Time](#post-mortem-time)
- [Documentation](#documentation)
  - [Incident Timeline](#incident-timeline)
  - [Meeting Details](#meeting-details)
  - [Incident Description](#incident-description)
- [Foster documentation and eas of use](#foster-documentation-and-eas-of-use)
- [Things to not do](#things-to-not-do)
  - [Things to do](#things-to-do)
- [Post-Post-Mortem](#post-post-mortem)
- [Resources](#resources)
- [Table of content](#table-of-content)