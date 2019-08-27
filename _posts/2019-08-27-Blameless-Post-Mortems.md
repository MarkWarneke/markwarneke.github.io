---
layout: post
title: Blameless Post-Mortems
subtitle:
bigimg:
  - "/img/55QfOLiYqWQ.jpeg": "https://unsplash.com/photos/55QfOLiYqWQ"
image: "/img/55QfOLiYqWQ.jpeg"
share-img: "/img/55QfOLiYqWQ.jpeg"
tags: [draft]
comments: true
time: 4
---

What are you going to do after an incident happen? Find the one to blame...? A better idea is to create an environment where failures are accepted and appreciated. You should create an environment of learning and reinforce that failing fast and learning from mistakes is something to strive for.

## Introduction

Post-Mortems should help us examine

> mistakes in a way that focuses on the situational aspects of a failure’s mechanism and the decision-making process of individuals proximate to the failure. *by John Allspaw*

Schedule post-mortem as soon as possible after the accident occurs and before memories and the links between cause and effect fade or circumstances change

## Environment

- Construct a timeline
- Gather details from multiple perspectives 
- Ensuring no punishment of people for making mistakes is happening
- Empower all engineers to improve safety by allowing them to give detailed accounts of their contributions to failures
- Enable and encourage people who do make mistakes to be the experts who educate the rest of the organization on how not to make them in the future
- Accept that there is always a discretionary space where humans can decide to take action or not, and that the judgment of those decisions lies in hindsight
- Propose countermeasures to prevent a similar accident from happening in the future and ensure these countermeasures are recorded with a target date and an owner for follow-up

## Stakeholders

Include people to the post mortem who...

- have been involved in decisions that may have contributed to the problem
- identified the problem
- responded to the problem
- diagnosed the problem
- were affected by the problem
- is interested in attending the meeting.

## Tasks

Focus on:

> Why did it make sense to me when I took that action?

an work from there.

1. record the timeline of relevant events as they occurred (to best knowledge)
   1. what actions have been taken
   2. at what time
   3. with what effect
   4. which investigation pathes 
   5. which resolutions have been considered
2. reserve enough time for
   1. brainstorming 
   2. deciding countermeasures to implement
      1. prioritized them
      2. assign owner
      3. create implementation timeline

Doing this demonstrates that continuos improvement of daily work is more important than doing daily work itself.

## Documentation

What should be documented to create a good post-mortem and keep track to foster learning.

- Post-Mortem Title
- Incident Start Time
- Incident End Time
- Incident Detect Time
- Additional Times if necessary (e.g. First User Impact, First User Report, Hotfix)
- Severity
- Contact Person
- Post-Mortem Date
- Post-Mortem was created By
- Post-Mortem was facilitated By
- What happened (Bullet point list with timestamps)
- Additional Info (e.g. images, ! no logs, no stack traces)
- Remediation
  - Bug Tickets created
  - Short Summary
- Tags

## Foster Documentation and eas of use

- make it easy to document post-mortems (e.g. through tools) 
 - more people will record and detail the outcomes of post-mortems
  -  that enables more organizational learning

## Avoid

Avoid using “would have” or “could have” in statements.
Be specific, its not a guessing game.
Instead use terms of the system that actually exists and happend.
What did you do or didn't do that lead to the issue.

## Post-Post-Mortem

After a Post-Mortem we should

- widely announce the availability of the meeting notes and any associated artifacts
- place information on a centralized location where the entire organization can access it and learn from the incident
- encourage others in the organization to read them to increase organizational learning
- increases the transparency with internal and external customers
  - which will in turn increases trust

## Resources

[The DevOps Handbook](https://learning.oreilly.com/library/view/the-devops-handbook/9781457191381/DOHB-ch_19.xhtml)


## Table of content

- [Introduction](#introduction)
- [Environment](#environment)
- [Stakeholders](#stakeholders)
- [Tasks](#tasks)
- [Documentation](#documentation)
- [Foster Documentation and eas of use](#foster-documentation-and-eas-of-use)
- [Avoid](#avoid)
- [Post-Post-Mortem](#post-post-mortem)
- [Resources](#resources)
- [Table of content](#table-of-content)