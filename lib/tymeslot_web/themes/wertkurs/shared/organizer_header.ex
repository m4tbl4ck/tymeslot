defmodule TymeslotWeb.Themes.Wertkurs.Shared.OrganizerHeader do
  @moduledoc """
  Compact organiser row used by the schedule and booking steps: avatar, name,
  and the duration of the meeting type being booked.
  """
  use Phoenix.Component
  use Gettext, backend: TymeslotWeb.Gettext

  alias Tymeslot.{Demo, Profiles}
  alias TymeslotWeb.Themes.Shared.LocalizationHelpers

  attr :organizer_profile, :map, required: true
  attr :meeting_type, :map, default: nil
  attr :selected_duration, :any, default: nil

  @spec organizer_header_small(map()) :: Phoenix.LiveView.Rendered.t()
  def organizer_header_small(assigns) do
    ~H"""
    <div class="organizer-profile-small">
      <img
        src={Demo.avatar_url(@organizer_profile, :thumb)}
        alt={Demo.avatar_alt_text(@organizer_profile)}
        class="avatar-image-small"
      />
      <div class="organizer-info-small">
        <div class="organizer-name">{dgettext("booking", "Schedule with")}</div>
        <div class="organizer-name-full">
          {Profiles.display_name(@organizer_profile) || ""}
        </div>
        <div class="meeting-duration">
          <%= if @meeting_type do %>
            {LocalizationHelpers.format_duration(@meeting_type.duration_minutes)}
          <% else %>
            {LocalizationHelpers.format_duration(@selected_duration)}
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
