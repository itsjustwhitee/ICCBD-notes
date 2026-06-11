#import "@preview/justwhitee-notes:0.2.2": *

#show: project.with(
  title: "Infrastractures for Cloud Computing and Big Data",
  subject: "Master in Computer Engineering",
  professor: "Andrea Sabbioni, Antonio Corradi",
  author: "Matteo Fontolan",
  year: "2025/2026",
  logo-personal: image("default/logo.svg"),
  logo-subject: image("assets/icon.jpg"),
  bento-url: "https://itsjustwhitee.github.io/bento/",
  paypal-url: "https://www.paypal.com/paypalme/justwhitee",
  contact-url: "https://t.me/justwhitee",
  lang: "en",
)

// ─────────────────────────────────────────────────────────────
// PART 1: Foundations
// ─────────────────────────────────────────────────────────────
#include "chapters/01-introduction.typ"
#include "chapters/02-goals-basics-models.typ"
#include "chapters/03-resource-management-models.typ"
#include "chapters/03b-unix-files-atomicity.typ"

// ─────────────────────────────────────────────────────────────
// PART 2: Middleware and Communication
// ─────────────────────────────────────────────────────────────
#include "chapters/04-microservices-containers.typ"
#include "chapters/05-middleware-cloud.typ"
#include "chapters/07-corba-mom.typ"
#include "chapters/06-cloud-dc-strategies.typ"

// ─────────────────────────────────────────────────────────────
// PART 3: Cloud Infrastructure
// ─────────────────────────────────────────────────────────────
#include "chapters/08-kubernetes.typ"
#include "chapters/10-openstack.typ"
#include "chapters/11-serverless.typ"

// ─────────────────────────────────────────────────────────────
// PART 4: Dependability and QoS
// ─────────────────────────────────────────────────────────────
#include "chapters/12-replication.typ"
#include "chapters/13-group-policies.typ"
#include "chapters/14-qos.typ"

// ─────────────────────────────────────────────────────────────
// PART 5: Big Data Infrastructure
// ─────────────────────────────────────────────────────────────
#include "chapters/09-overlay-filesystems.typ"
#include "chapters/15-data-storage.typ"
#include "chapters/16-data-batching.typ"
#include "chapters/17-streaming.typ"
