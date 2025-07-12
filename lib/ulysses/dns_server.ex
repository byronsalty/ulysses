defmodule Ulysses.DnsServer do
  @dns_port 53

  def start_link(_) do
    Task.start_link(fn -> listen() end)
  end

  def listen do
    {:ok, socket} = :gen_udp.open(@dns_port, [:binary, active: false, reuseaddr: true])
    loop(socket)
  end

  defp loop(socket) do
    {:ok, {ip, port, packet}} = :gen_udp.recv(socket, 0)
    {:ok, dns} = :inet_dns.decode(packet)
    [query] = dns.qd
    domain = to_string(query.domain)

    if Ulysses.DomainCache.allowed?(domain) do
      forward_query(socket, ip, port, packet)
    else
      Ulysses.DomainCache.log(domain)
      reply_nxdomain(socket, ip, port, dns)
    end

    loop(socket)
  end

  defp forward_query(socket, ip, port, packet) do
    # TODO: Add upstream forwarding
  end

  defp reply_nxdomain(socket, ip, port, dns) do
    reply = %{dns | anlist: [], ra: true, rcode: 3} # NXDOMAIN
    :gen_udp.send(socket, ip, port, :inet_dns.encode(reply))
  end
end
