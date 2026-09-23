defmodule TymeslotWeb.Themes.Wertkurs.Scheduling.Components.OverviewComponent do
  @moduledoc """
  Step 1 — the organiser's intro and the meeting-type cards.

  Werner (the pixel flamingo) carries the empty state: a booking page with no
  bookable meeting types is the one screen with nothing useful to say, so the
  mascot says it instead of a grey box.
  """
  use TymeslotWeb, :live_component
  use Gettext, backend: TymeslotWeb.Gettext

  alias Tymeslot.Demo
  alias Tymeslot.Meetings.Approval
  alias Tymeslot.MeetingTypes
  alias Tymeslot.Profiles
  alias TymeslotWeb.Themes.Shared.BookingText
  alias TymeslotWeb.Themes.Shared.Components.ApprovalNotice
  alias TymeslotWeb.Themes.Shared.LocalizationHelpers
  alias TymeslotWeb.Themes.Wertkurs.Shared.StepRail

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, Map.drop(assigns, [:flash, :socket]))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("select_duration", %{"duration" => duration}, socket) do
    new_duration =
      if socket.assigns[:selected_duration] == duration, do: nil, else: duration

    send(self(), {:step_event, :overview, :select_duration, new_duration})
    {:noreply, assign(socket, :selected_duration, new_duration)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next_step", _params, socket) do
    send(self(), {:step_event, :overview, :next_step, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="scheduling-box" data-locale={@locale}>
      <div class="slide-container">
        <div class="slide active">
          <div class="slide-content overview-slide">
            <StepRail.step_rail current_state={:overview} />

            <h1 class="slide-title">
              {BookingText.heading(@organizer_profile, :wertkurs, display_name(@organizer_profile))}
            </h1>

            <div class="organizer-profile">
              <div class="organizer-avatar">
                <img
                  src={Demo.avatar_url(@organizer_profile, :thumb)}
                  alt={Demo.avatar_alt_text(@organizer_profile)}
                  class="avatar-image"
                />
                <div class="avatar-checkmark">✓</div>
              </div>
              <div class="organizer-info">
                <p class="organizer-greeting">
                  {BookingText.greeting(@organizer_profile, display_name(@organizer_profile))}
                </p>
                <p class="organizer-instruction">
                  {BookingText.instruction(@organizer_profile)}
                </p>
              </div>
            </div>

            <%= if @username_context && @meeting_types == [] do %>
              <div class="overview-empty-state">
                <p class="overview-empty-title">
                  {dgettext("booking", "No meeting types available")}
                </p>
                <p class="overview-empty-subtitle">
                  {dgettext("booking", "Please contact the organizer")}
                </p>
              </div>
            <% else %>
              <div class="duration-grid">
                <%= for meeting_type <- @meeting_types do %>
                  <% slug = MeetingTypes.effective_slug(meeting_type) %>
                  <div class={["duration-card", @selected_duration == slug && "selected"]}>
                    <button
                      phx-click="select_duration"
                      phx-value-duration={slug}
                      phx-target={@myself}
                      class="duration-button"
                      data-testid="duration-option"
                      data-duration={slug}
                    >
                      <div class="duration-icon shrink-0">
                        {render_icon(meeting_type.icon || default_icon(meeting_type))}
                      </div>
                      <div class="duration-info">
                        <div class="duration-name">
                          {meeting_type.name}
                          <ApprovalNotice.pill :if={Approval.required?(meeting_type)} />
                        </div>
                        <div class="duration-time">
                          {LocalizationHelpers.format_duration(meeting_type.duration_minutes)}
                        </div>
                        <div class="duration-description">{meeting_type.description}</div>
                      </div>
                    </button>
                  </div>
                <% end %>
              </div>
            <% end %>

            <div class="slide-actions">
              <button
                class={["next-button", is_nil(@selected_duration) && "disabled"]}
                phx-click="next_step"
                phx-target={@myself}
                data-testid="next-step"
                disabled={is_nil(@selected_duration)}
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

  defp display_name(profile), do: Profiles.display_name(profile) || "there"

  defp default_icon(meeting_type) do
    case meeting_type.duration_minutes do
      15 -> "hero-bolt"
      30 -> "hero-chat-bubble-left-right"
      60 -> "hero-clipboard-document-check"
      90 -> "hero-chart-bar"
      120 -> "hero-flag"
      _duration -> "hero-clock"
    end
  end

  # Only the hero-icon path needs sanitising as a CSS class name; emoji icons
  # render as text content and are escaped by Phoenix.
  defp render_icon(icon) do
    assigns = %{icon: icon, safe_icon: sanitize_css_class(icon)}

    case icon do
      "none" ->
        ~H""

      "hero-" <> _rest ->
        ~H"""
        <.icon name={@safe_icon} class="hero-icon hero-icon--md" />
        """

      _emoji ->
        ~H"""
        <div class="emoji-icon">{@icon}</div>
        """
    end
  end

  defp sanitize_css_class(class_name) do
    class_name
    |> String.replace(~r/[^a-zA-Z0-9\-_]/, "")
    |> String.slice(0, 100)
  end
end
