defmodule Ulysses.DnsServer do
  @dns_port 53
  @upstream_dns {~c"8.8.8.8", 53}

  def start_link(_) do
    Task.start_link(fn -> listen() end)
  end

  def listen do
    {:ok, socket} = :gen_udp.open(@dns_port, [:binary, active: false, reuseaddr: true])
    loop(socket)
  end

  defp loop(socket) do
    {:ok, {ip, port, packet}} = :gen_udp.recv(socket, 0)
    {:ok, dns_rec} = :inet_dns.decode(packet)
    # dns_rec is {:dns_rec, header, qd, anlist, nslist, arlist}
    [query | _] = elem(dns_rec, 2)
    domain =
      case query do
        {:dns_query, domain_charlist, _type, _class, _unicast?} -> to_string(domain_charlist)
        _ -> "unknown"
      end

    norm_domain = domain |> String.trim_trailing(".") |> String.downcase()

    IO.puts("[DNS] Received query for: #{norm_domain}")

    if Ulysses.DomainCache.allowed?(norm_domain) do
      IO.puts("[DNS] Allowed: #{norm_domain} (forwarding to upstream)")
      forward_query(socket, ip, port, packet)
    else
      Ulysses.DomainCache.log(norm_domain)
      IO.puts("[DNS] Blocked: #{norm_domain} (NXDOMAIN, added to pending)")
      reply_nxdomain(socket, ip, port, dns_rec)
    end

    loop(socket)
  end

  defp forward_query(socket, ip, port, packet) do
    # Forward the DNS query to the upstream server (Google DNS)
    {:ok, upstream_socket} = :gen_udp.open(0, [:binary, active: false])
    :ok = :gen_udp.send(upstream_socket, elem(@upstream_dns, 0), elem(@upstream_dns, 1), packet)

    # Wait for the response from the upstream DNS
    case :gen_udp.recv(upstream_socket, 0, 2000) do
      {:ok, {_upstream_ip, _upstream_port, response}} ->
        :gen_udp.send(socket, ip, port, response)
      {:error, _reason} ->
        # If upstream fails, reply with SERVFAIL
        reply_servfail(socket, ip, port, packet)
    end
    :gen_udp.close(upstream_socket)
  end

  defp reply_servfail(socket, ip, port, packet) do
    {:ok, dns_tuple} = :inet_dns.decode(packet)
    %{header: header, qd: qd, anlist: anlist, nslist: nslist, arlist: arlist} = dns_tuple_to_map(dns_tuple)
    # Update header: ra (index 6) = true, rcode (index 9) = 2 (SERVFAIL)
    header = put_elem(header, 6, true)
    header = put_elem(header, 9, 2)
    reply_tuple = {:dns_rec, header, qd, [], nslist, arlist}
    :gen_udp.send(socket, ip, port, :inet_dns.encode(reply_tuple))
  end

  defp reply_nxdomain(socket, ip, port, dns_tuple) do
    %{header: header, qd: qd, anlist: anlist, nslist: nslist, arlist: arlist} = dns_tuple_to_map(dns_tuple)
    # Update header: ra (index 6) = true, rcode (index 9) = 3 (NXDOMAIN)
    header = put_elem(header, 6, true)
    header = put_elem(header, 9, 3)
    reply_tuple = {:dns_rec, header, qd, [], nslist, arlist}
    :gen_udp.send(socket, ip, port, :inet_dns.encode(reply_tuple))
  end

  defp dns_tuple_to_map({:dns_rec, header, qd, anlist, nslist, arlist}) do
    %{header: header, qd: qd, anlist: anlist, nslist: nslist, arlist: arlist}
  end

end
