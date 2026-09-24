defmodule TymeslotWeb.Themes.Wertkurs.Scheduling.Components.ScheduleComponent do
  @moduledoc """
  Step 2 — date and time.

  The wertkurs flow is a single Monday-anchored week strip with the day's slots
  underneath: one decision per row, nothing to scan. Week navigation boundaries
  come from `CalendarNavigation`, so the booker can never page into a week the
  organiser has not opened.

  Selecting a day is not a toggle — clicking the already-selected day re-selects
  it. The step opens on the first bookable day, so the highlighted day is the
  one most likely to be clicked first; a toggle would turn that first click into
  an empty slot list that looks identical to "no availability".
  """
  use TymeslotWeb, :live_component
  use Gettext, backend: TymeslotWeb.Gettext

  alias TymeslotWeb.Components.MeetingUtils
  alias TymeslotWeb.Live.Scheduling.CalendarHelpers
  alias TymeslotWeb.Live.Scheduling.CalendarNavigation
  alias TymeslotWeb.Themes.Shared.LocalizationHelpers
  alias TymeslotWeb.Themes.Shared.SlotGrouping
  alias TymeslotWeb.Themes.Wertkurs.Shared.OrganizerHeader
  alias TymeslotWeb.Themes.Wertkurs.Shared.StepRail

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, Map.drop(assigns, [:flash, :socket]))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("select_date", %{"date" => date}, socket) do
    send(self(), {:step_event, :schedule, :select_date, date})

    {:noreply,
     socket
     |> assign(:selected_date, date)
     |> assign(:selected_time, nil)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("select_time", %{"time" => time}, socket) do
    new_time = if socket.assigns[:selected_time] == time, do: nil, else: time
    send(self(), {:step_event, :schedule, :select_time, new_time})
    {:noreply, assign(socket, :selected_time, new_time)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle_hour", %{"hour" => hour}, socket) do
    send(self(), {:step_event, :schedule, :toggle_hour, hour})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("change_timezone", %{"timezone" => timezone}, socket) do
    send(self(), {:step_event, :schedule, :change_timezone, timezone})

    {:noreply,
     socket
     |> assign(:timezone_dropdown_open, false)
     |> assign(:timezone_search, "")}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle_timezone_dropdown", _params, socket) do
    send(self(), {:step_event, :schedule, :toggle_timezone_dropdown, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_timezone_dropdown", _params, socket) do
    send(self(), {:step_event, :schedule, :close_timezone_dropdown, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("search_timezone", params, socket) do
    send(self(), {:step_event, :schedule, :search_timezone, params})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("prev_week", _params, socket) do
    send(self(), {:step_event, :schedule, :prev_week, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next_week", _params, socket) do
    send(self(), {:step_event, :schedule, :next_week, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("back_step", _params, socket) do
    send(self(), {:step_event, :schedule, :back_step, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next_step", _params, socket) do
    send(self(), {:step_event, :schedule, :next_step, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="scheduling-box" data-locale={@locale}>
      <div class="slide-container">
        <div class="slide active">
          <div class="slide-content schedule-slide">
            <StepRail.step_rail current_state={:schedule} questions?={questions?(assigns)} />

            <div class="schedule-header">
              <OrganizerHeader.organizer_header_small
                organizer_profile={@organizer_profile}
                meeting_type={@meeting_type}
                selected_duration={@selected_duration}
              />
              <%!-- No timezone picker: the audience is in one timezone. Slots are
                    still rendered in the visitor's browser timezone (LiveSocket
                    connect param, see ThemeUtils.assign_user_timezone/2); only
                    the manual override is gone. --%>
            </div>

            <div class="schedule-grid">
              <div class="calendar-section">
                <div class="calendar-header">
                  <button
                    class="calendar-nav-button phx-click-loading:animate-pulse"
                    phx-click="prev_week"
                    phx-target={@myself}
                    phx-disable-with="…"
                    aria-label={dgettext("booking", "Previous week")}
                    disabled={
                      CalendarNavigation.prev_week_disabled?(@current_week_start, @user_timezone)
                    }
                  >
                    ←
                  </button>
                  <h3 class="calendar-month-year">
                    {LocalizationHelpers.get_week_display(@current_week_start)}
                  </h3>
                  <div class="cluster cluster-xs">
                    <div :if={@availability_status == :error} class="calendar-error-inline">
                      <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                        />
                      </svg>
                      {dgettext("booking", "Service slow")}
                    </div>
                    <button
                      class="calendar-nav-button phx-click-loading:animate-pulse"
                      phx-click="next_week"
                      phx-target={@myself}
                      phx-disable-with="…"
                      aria-label={dgettext("booking", "Next week")}
                      disabled={
                        CalendarNavigation.next_week_disabled?(
                          @current_week_start,
                          @user_timezone,
                          @booking_window_days
                        )
                      }
                    >
                      →
                    </button>
                  </div>
                </div>

                <div class="calendar-grid">
                  <%= for day <- CalendarHelpers.get_week_days(@current_week_start, @organizer_profile, @month_availability_map, @user_timezone, @meeting_type) do %>
                    <button
                      class={[
                        "calendar-day",
                        @selected_date == day.date && "selected",
                        day.loading && "calendar-day--loading"
                      ]}
                      data-testid="calendar-day"
                      data-date={day.date}
                      phx-click="select_date"
                      phx-value-date={day.date}
                      phx-target={@myself}
                      disabled={not day.available || day.loading}
                      aria-label={LocalizationHelpers.format_full_date_label(day.date)}
                      aria-current={day.today && "date"}
                    >
                      <div class="day-name" aria-hidden="true">{day.day_name}</div>
                      <div class="day-number" aria-hidden="true">{day.day_number}</div>
                    </button>
                  <% end %>
                </div>
              </div>

              <div class="time-slots-section" id="slots-container" phx-hook="AutoScrollToSlots">
                <h3 class="time-slots-section-heading" tabindex="-1">
                  {dgettext("booking", "Available Times")}
                </h3>
                <% normalized_slots = MeetingUtils.normalize_slot_list(@available_slots) %>
                <% slots_loaded? =
                  @selected_date && !@loading_slots && !@calendar_error && normalized_slots != [] %>
                <%!-- Screen-reader-only announcement of the slot-loading state, so
                      keyboard/AT users hear the result of picking a day. --%>
                <div class="sr-only" role="status" aria-live="polite" aria-atomic="true">
                  <%= cond do %>
                    <% is_nil(@selected_date) -> %>
                      {dgettext("booking", "Please select a date to see available times")}
                    <% @loading_slots -> %>
                      {dgettext("booking", "Loading available times...")}
                    <% @calendar_error -> %>
                      {@calendar_error}
                    <% normalized_slots != [] -> %>
                      {dgettext("booking", "Available Times")}
                    <% true -> %>
                      {dgettext("booking", "This date is fully booked")}
                  <% end %>
                </div>

                <div class="time-slots-grid scroll-y" data-slots-loaded={slots_loaded? && @selected_date}>
                  <%= if @selected_date do %>
                    <%= if @loading_slots do %>
                      <div class="loading-slots">
                        <span>{dgettext("booking", "Loading available times...")}</span>
                      </div>
                    <% else %>
                      <div :if={@calendar_error} class="calendar-error">{@calendar_error}</div>

                      <%= if !@calendar_error && normalized_slots != [] do %>
                        <% grouping =
                          SlotGrouping.group(
                            normalized_slots,
                            @slot_interval_minutes,
                            @duration_minutes
                          ) %>
                        <%= case grouping do %>
                          <% {:flat, periods} -> %>
                            <%= for {period, slots} <- periods, slots != [] do %>
                              <div class="time-period-section">
                                <h4 class="time-period-header">{period}</h4>
                                <div class="time-period-slots">
                                  <.slot_button
                                    :for={slot_value <- slots}
                                    slot_value={slot_value}
                                    selected={@selected_time == slot_value}
                                    target={@myself}
                                  />
                                </div>
                              </div>
                            <% end %>
                          <% {:hours, periods} -> %>
                            <% open = SlotGrouping.effective_expanded_hour(@expanded_hour, grouping) %>
                            <% selected_hour = SlotGrouping.selected_hour(grouping, @selected_time) %>
                            <%= for {period, hours} <- periods, hours != [] do %>
                              <div class="time-period-section">
                                <h4 class="time-period-header">{period}</h4>
                                <div class="time-period-slots">
                                  <%= for {hour, hour_slots} <- hours do %>
                                    <button
                                      type="button"
                                      class={[
                                        "time-slot time-slot--hour",
                                        open == hour && "expanded",
                                        open != hour && selected_hour == hour && "selected"
                                      ]}
                                      data-testid="slot-hour"
                                      phx-click="toggle_hour"
                                      phx-value-hour={hour}
                                      phx-target={@myself}
                                      aria-expanded={to_string(open == hour)}
                                      aria-controls={open == hour && "slot-hour-panel-#{hour}"}
                                      aria-label={
                                        dngettext(
                                          "booking",
                                          "%{hour}, %{count} available time",
                                          "%{hour}, %{count} available times",
                                          length(hour_slots),
                                          hour: SlotGrouping.hour_label(hour),
                                          count: length(hour_slots)
                                        )
                                      }
                                    >
                                      <span class="slot-hour-label" aria-hidden="true">
                                        {SlotGrouping.hour_label(hour)}
                                      </span>
                                      <span class="slot-hour-count" aria-hidden="true">
                                        {length(hour_slots)}
                                      </span>
                                    </button>
                                  <% end %>
                                </div>
                                <%= for {hour, hour_slots} <- hours, hour == open do %>
                                  <div
                                    class="time-period-slots time-period-slots--minutes"
                                    id={"slot-hour-panel-#{hour}"}
                                    role="group"
                                    aria-label={SlotGrouping.hour_label(hour)}
                                  >
                                    <.slot_button
                                      :for={slot_value <- hour_slots}
                                      slot_value={slot_value}
                                      selected={@selected_time == slot_value}
                                      target={@myself}
                                    />
                                  </div>
                                <% end %>
                              </div>
                            <% end %>
                        <% end %>
                      <% else %>
                        <div :if={!@calendar_error} class="no-slots">
                          <p>{dgettext("booking", "This date is fully booked")}</p>
                          <p>{dgettext("booking", "Please select another date")}</p>
                        </div>
                      <% end %>
                    <% end %>
                  <% else %>
                    <div class="no-slots">
                      <p>{dgettext("booking", "Please select a date to see available times")}</p>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="slide-actions horizontal" data-testid="schedule-actions">
              <button
                :if={@entered_via_overview}
                class="prev-button"
                phx-click="back_step"
                phx-target={@myself}
                data-testid="back-step"
              >
                ← {dgettext("booking", "back")}
              </button>
              <button
                class={["next-button", !(@selected_date && @selected_time) && "disabled"]}
                phx-click="next_step"
                phx-target={@myself}
                data-testid="next-step"
                disabled={is_nil(@selected_date) or is_nil(@selected_time)}
              >
                {dgettext("booking", "next")} →
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # One definition of the slot button, so the flat grid and the minutes nested
  # under an expanded hour cannot drift apart in markup.
  attr :slot_value, :string, required: true
  attr :selected, :boolean, default: false
  attr :loading, :boolean, default: false
  attr :target, :any, required: true

  @spec slot_button(map()) :: Phoenix.LiveView.Rendered.t()
  defp slot_button(assigns) do
    ~H"""
    <button
      type="button"
      class={["time-slot", @selected && "selected"]}
      data-testid="time-slot"
      data-time={@slot_value}
      phx-click="select_time"
      phx-value-time={@slot_value}
      phx-target={@target}
      disabled={@loading}
    >
      {LocalizationHelpers.format_time_by_locale(CalendarHelpers.parse_slot_time(@slot_value))}
    </button>
    """
  end

  # The questions step only exists when the meeting type has custom fields, so
  # the rail must not promise it otherwise.
  defp questions?(assigns) do
    Enum.any?(
      [assigns[:custom_field_definitions], assigns[:custom_fields_snapshot]],
      &(is_list(&1) and &1 != [])
    )
  end
end
