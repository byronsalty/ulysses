defmodule Ulysses.DomainCache do
  use GenServer

  @impl true
  def init(_init_arg) do
    # Add github.com to allowed set by default
    allowed = MapSet.new(["github.com"])
    pending = MapSet.new()
    {:ok, %{allowed: allowed, pending: pending}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{allowed: MapSet.new(), pending: MapSet.new()}, name: __MODULE__)
  end

  # Public API
  def allowed?(domain), do: GenServer.call(__MODULE__, {:allowed?, normalize_domain(domain)})
  def allow(domain), do: GenServer.cast(__MODULE__, {:allow, normalize_domain(domain)})
  def log(domain), do: GenServer.cast(__MODULE__, {:log, normalize_domain(domain)})

  def subscribe_pending() do
    Phoenix.PubSub.subscribe(Ulysses.PubSub, "pending_domains")
  end

  def list_pending(), do: GenServer.call(__MODULE__, :list_pending)

  defp normalize_domain(domain) do
    domain
    |> to_string()
    |> String.trim_trailing(".")
    |> String.downcase()
  end

  # GenServer callbacks
  @impl true
  def handle_call({:allowed?, domain}, _from, state) do
    {:reply, MapSet.member?(state.allowed, domain), state}
  end

  @impl true
def handle_call(:list_pending, _from, state) do
    {:reply, MapSet.to_list(state.pending), state}
  end

  @impl true
def handle_cast({:allow, domain}, state) do
    updated = %{
      allowed: MapSet.put(state.allowed, domain),
      pending: MapSet.delete(state.pending, domain)
    }
    {:noreply, updated}
  end

  @impl true
  def handle_cast({:log, domain}, state) do
    if MapSet.member?(state.allowed, domain) or MapSet.member?(state.pending, domain) do
      {:noreply, state}
    else
      new_state = %{state | pending: MapSet.put(state.pending, domain)}
      Phoenix.PubSub.broadcast(Ulysses.PubSub, "pending_domains", {:pending_domain, domain})
      {:noreply, new_state}
    end
  end
end
