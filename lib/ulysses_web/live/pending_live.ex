defmodule UlyssesWeb.PendingLive do
  use UlyssesWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket), do: Ulysses.DomainCache.subscribe_pending()
    {:ok, assign(socket, pending: Ulysses.DomainCache.list_pending())}
  end

  def handle_info({:pending_domain, _domain}, socket) do
    {:noreply, assign(socket, pending: Ulysses.DomainCache.list_pending())}
  end

  def handle_event("allow", %{"domain" => domain}, socket) do
    Ulysses.DomainCache.allow(domain)
    {:noreply, assign(socket, pending: Ulysses.DomainCache.list_pending())}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl mb-4">🛡️ Ulysses: Domain Review</h1>
    <ul class="space-y-2">
      <%= for domain <- Enum.map(@pending, &(&1 |> String.trim_trailing(".") |> String.downcase())) do %>
        <li class="flex justify-between items-center border-b pb-2">
          <span><%= domain %></span>
          <button phx-click="allow" phx-value-domain={domain} class="bg-green-600 text-white px-3 py-1 rounded">
            Allow
          </button>
        </li>
      <% end %>
    </ul>
    """
  end
end
