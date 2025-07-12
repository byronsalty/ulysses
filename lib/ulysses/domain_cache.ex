defmodule Ulysses.DomainCache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{allowed: MapSet.new(), pending: MapSet.new()}, name: __MODULE__)
  end

  # Public API
  def allowed?(domain), do: GenServer.call(__MODULE__, {:allowed?, domain})
  def allow(domain), do: GenServer.cast(__MODULE__, {:allow, domain})
  def log(domain), do: GenServer.cast(__MODULE__, {:log, domain})
  def list_pending(), do: GenServer.call(__MODULE__, :list_pending)

  # GenServer callbacks
  def handle_call({:allowed?, domain}, _from, state) do
    {:reply, MapSet.member?(state.allowed, domain), state}
  end

  def handle_call(:list_pending, _from, state) do
    {:reply, MapSet.to_list(state.pending), state}
  end

  def handle_cast({:allow, domain}, state) do
    updated = %{
      allowed: MapSet.put(state.allowed, domain),
      pending: MapSet.delete(state.pending, domain)
    }
    {:noreply, updated}
  end

  def handle_cast({:log, domain}, state) do
    state =
      if MapSet.member?(state.allowed, domain) or MapSet.member?(state.pending, domain) do
        state
      else
        %{state | pending: MapSet.put(state.pending, domain)}
      end

    {:noreply, state}
  end
end
