# 🛡️ Ulysses

**Ulysses** is a local DNS firewall and accountability system built with Elixir + Phoenix LiveView. Inspired by the concept of a **Ulysses Pact**—a commitment made in a moment of clarity to constrain future behavior—this tool helps you intentionally control internet access by allowing only whitelisted domains and blocking all others.

It acts as a self-binding agreement to prevent distraction and promote focused, deliberate browsing.

---

## 🎯 Project Goals

- Run a local DNS nameserver via Elixir
- Block all outbound domain requests by default
- Maintain an in-memory whitelist using a `GenServer`
- Allow human-in-the-loop review and approval via a LiveView UI
- Provide visibility into all attempted DNS lookups
- Serve as a digital accountability device

---

## 🧠 Inspiration

The name "Ulysses" comes from the **Ulysses Pact**—a decision made while rational and focused to avoid succumbing to future temptation. Much like Odysseus tying himself to the mast to resist the Sirens, this tool blocks all unknown domains unless explicitly approved.

---

## 🧱 Core Components

- `Ulysses.DomainCache`  
  A GenServer that holds `allowed` and `pending` domain sets in memory.
  
- `Ulysses.DnsServer`  
  A UDP DNS listener using `:gen_udp` and `:inet_dns` that checks the cache, forwards approved queries, and blocks the rest with `NXDOMAIN`.

- `UlyssesWeb.PendingLive`  
  A Phoenix LiveView UI that shows pending domains and allows approval via click.

---

## 📐 System Diagram (Mermaid)

```mermaid
flowchart LR
    A[Client / App] --> B[Ulysses DNS Server]
    B -->|Allowed| C[Upstream DNS (1.1.1.1)]
    B -->|Blocked| D[LiveView UI: Pending]
    D -->|Click Allow| B
