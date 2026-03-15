Realistic Performance Requirement Document

Project: Retail Web Application
Release: Summer Promo Release
Prepared by: Product / Business / Engineering
Version: Draft 0.8

1. Objective

Validate that the web application can support expected traffic during the upcoming promotional campaign without major slowdown in customer-facing journeys.

Known business concern: search and checkout were reported slow during last campaign.

2. Scope

In scope:

Homepage

Login

Product Search

Product Details

Add to Cart

Checkout

Payment redirect

Out of scope:

Admin portal

Internal reporting dashboards

Seller onboarding flows

3. Business Inputs Provided

These are the kinds of things business usually gives.

Marketing expects traffic to increase significantly during the summer campaign.

Last major sale had approximately 2.3x increase over normal traffic.

Product team says search, cart, and checkout are the most important flows.

Customer support reported users experienced slowness during payment handoff last time.

Business wants the platform to remain “responsive.”

Campaign will run from June 10 to June 17.

Peak traffic is expected in the evening between 7 PM and 11 PM IST.

Around 70% of traffic is mobile web.

New coupon engine is included in this release.

Notice the problem:
this is useful, but still not enough to directly build a JMeter test.

4. Technical Inputs Provided

These may come from engineering or DevOps.

Application is deployed in pre-production.

Pre-prod has:

2 web nodes

3 app nodes

1 PostgreSQL primary

Redis cache

Production has higher capacity than pre-prod.

Autoscaling is enabled in production but not fully enabled in pre-prod.

Monitoring available:

Grafana

App logs

DB monitoring

Payment gateway in test environment is a sandbox and may not reflect real latency.

CDN is partially configured in pre-prod.

Again, useful, but incomplete.

5. Historical Information Available

This is often where testers start deriving.

Last sale event peak:

~180,000 sessions/day

search traffic significantly higher than normal

checkout drop-off increased during peak hours

Average weekday traffic is lower and stable.

Engineering shared that during the last sale:

DB CPU reached high utilization

search API had higher latency

cart service showed some timeout spikes

But still:

no exact concurrent users

no exact TPS

no approved SLA table

no exact workload mix

This is very normal.

6. Requirements Explicitly Given

These are the things the tester can directly use.

Requirement	Status	Source
Search is critical	Given	Product
Checkout is critical	Given	Product
Peak window is 7 PM–11 PM IST	Given	Business
Traffic expected around 2x–3x normal	Given	Marketing
Last sale had 2.3x traffic	Given	Historical data
Mobile web dominates traffic	Given	Analytics/Product
Payment handoff had past slowness	Given	Support
New coupon engine must be included	Given	Engineering