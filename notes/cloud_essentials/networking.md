<link rel="stylesheet" href="./css/globals.css">

# networking

## the outcome we're after
the job of networking is getting all the pieces talking to each other, and getting
real users to your app <em>fast and safely</em>.
- your servers, databases and load balancers need to reach each other — but only the right ones.
- the public needs a fast, secure door into the parts you *choose* to expose.
- everything else stays hidden.

everything below is in service of that. work right → left: the destination is "users reach my app, components talk privately"; the road is the VPC and the pieces inside it.


## the core mental model: your own private network
when you build in AWS you get an <em>Amazon VPC (Virtual Private Cloud)</em> — your own
isolated slice of the AWS network.
- analogy: the [region](./global_infrastructure.md) is the city; a VPC is *your walled
  neighborhood* inside it. you decide what's built where, what roads connect to the
  outside world, and who gets through the gate.
- it's private by default — nothing inside is reachable from the internet until you
  deliberately open a path.
- it spans [availability zones](./global_infrastructure.md) in one region, so you can
  build redundantly across AZs while staying inside one network.

anchor everything that follows to this picture: a walled neighborhood you lay out yourself.


## inside the vpc
once you have the neighborhood, you divide it into lots and decide which ones face the street.

### subnets
a <em>subnet</em> is a section of your VPC — a block of addresses you carve out, usually one per AZ.
- **public subnet** — has a path to the internet. put the things users touch here (load balancers, public web servers).
- **private subnet** — no direct path in or out. put the things you want hidden here (databases, app servers).
- public vs private isn't a setting on the subnet itself — it's *whether its route table has a door to the internet*. that's the next piece.

### route tables
the <em>rules for where traffic goes</em> when it leaves a subnet — like street signs at each lot.
- a subnet pointed at an internet gateway is, by definition, public.
- a subnet with no such route stays private.

### internet gateway (igw)
the <em>front gate of the neighborhood</em> — the door between your VPC and the public internet.
- one per VPC; attach it, then route a public subnet to it.
- without an igw, nothing in the VPC can reach (or be reached from) the internet.

### nat gateway
lets a <em>private subnet reach out</em> to the internet without letting the internet reach *in*.
- analogy: residents can walk out to run errands, but strangers can't walk in.
- when to use: a private app server needs to download updates or call an external API, but must never accept inbound connections.
- contrast with igw: igw is a two-way door for public resources; NAT is a one-way exit for private ones.


## the security layer: two firewalls, not one
the VPC gives you *where* things sit; security groups and network ACLs control *who may pass*.
this pairing is a classic point of confusion — the contrast is the lesson. (part of
defense in depth — see [security & identity](./security_identity.md).)

### security groups
a firewall <em>around an instance</em> (e.g. one EC2 server) — like a guard at that building's door.
- **stateful**: if you allow a request in, the reply is automatically allowed back out. you don't write the return rule.
- **allow rules only**: you list what's permitted; everything else is implicitly denied.
- operates at the resource level — different instances can have different groups.

### network acls (nacls)
a firewall <em>around a whole subnet</em> — like a checkpoint at the neighborhood's edge.
- **stateless**: it checks every packet in *both* directions. allow inbound *and* the matching outbound, or replies get dropped.
- **allow and deny rules**: you can explicitly block traffic — useful for banning a bad IP across an entire subnet.
- operates at the subnet boundary — applies to everything inside it.

#### crisp contrast
| | security group | network acl |
|---|---|---|
| guards | a single instance | a whole subnet |
| state | stateful (return traffic auto-allowed) | stateless (must allow both directions) |
| rules | allow only | allow + deny |

think: security group = the building's guard; nacl = the neighborhood checkpoint. traffic passes the checkpoint first, then the building guard.


## getting traffic in & balanced
exposing one server is fragile. you want one stable front door spreading traffic across many.

### elastic load balancing (elb)
a <em>single entry point that spreads requests</em> across your servers so no one box is overwhelmed and a dead one is skipped.
- pairs naturally with [EC2 Auto Scaling](./compute_types.md): Auto Scaling adds/removes
  servers with demand, the load balancer routes only to the healthy ones. users see one
  steady address while the fleet changes underneath.

#### alb vs nlb
- **application load balancer (ALB)** — works at the request (HTTP/HTTPS) level. when to use: web apps that route by URL path or hostname.
- **network load balancer (NLB)** — works at the connection (TCP) level, built for extreme throughput and very low latency. when to use: high-performance or non-HTTP traffic.
- rule of thumb: routing on web content → ALB; raw speed and volume → NLB.


## reaching users globally & fast
the front door works; now shorten the distance between it and a user anywhere on earth.

### route 53
AWS's <em>managed DNS</em> — translates your domain name into the address users actually connect to.
- it's also a *router*: routing policies decide which endpoint a given user gets.
- when to use the policies: **latency** (send to the closest region), **geolocation** (route by where the user is), **weighted** (split traffic for testing), **failover** (send to a backup when the primary is down).

### cloudfront
a <em>content delivery network (CDN)</em> — caches copies of your content at
[edge locations](./global_infrastructure.md) near users.
- analogy: instead of every customer driving to the one warehouse, you stock corner shops everywhere.
- the first request fills the local cache; later nearby users are served from the edge — much lower latency.
- when to use: speed up static and streamed content (images, video, downloads) to a global audience.

### global accelerator
sends user traffic onto the <em>AWS private backbone</em> at the nearest edge, instead of crossing the open internet the whole way.
- contrast with cloudfront: cloudfront *caches content* at the edge; global accelerator *speeds the network path* to your application (no caching).
- when to use: latency-sensitive non-cacheable apps (gaming, voice, APIs) that need consistent global performance.


## connecting to on-prem (hybrid)
many companies keep a data center and want it joined to their VPC as if it were one network.

### aws vpn
an <em>encrypted tunnel over the public internet</em> between your network and your VPC.
- when to use: quick to set up, low cost, fine when occasional internet-path latency is acceptable.

### direct connect
a <em>private, dedicated physical line</em> from your data center to AWS.
- when to use: large, steady data transfer needing consistent low latency and bandwidth — and traffic that never touches the public internet.
- contrast: VPN rides the shared internet (cheap, fast to stand up); Direct Connect is your own private road (pricier, more consistent, more secure).


## putting the network together
right → left, the whole picture:
- the **VPC** is your private neighborhood inside a region, split into **public and private subnets** across AZs.
- **route tables + internet gateway** decide what faces the street; a **NAT gateway** lets private resources reach out without being reached.
- **security groups** (per instance, stateful) and **network ACLs** (per subnet, stateless, allow+deny) control who may pass — defense in depth.
- a **load balancer** is the steady front door, spreading traffic across an auto-scaling fleet.
- **Route 53** points users at the right endpoint; **CloudFront** caches content at the edge; **Global Accelerator** speeds the path there.
- **VPN** or **Direct Connect** stitches your own data center into the same network.

the result is the outcome we opened with: components talk privately, and users reach your app fast and safely.
