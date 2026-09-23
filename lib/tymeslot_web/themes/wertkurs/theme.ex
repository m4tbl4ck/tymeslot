defmodule TymeslotWeb.Themes.Wertkurs.Theme do
  @moduledoc """
  wertkurs theme (id "3") — light brand canvas, mint selection states, a
  week-strip schedule step and a pixel-art mascot cameo on confirmation.

  Visual language comes from the wertkurs design system: paper-white surfaces
  with grain, one mint accent field per surface, UPPERCASE headings in New Hero,
  8px corners everywhere (never pills), soft diffuse elevation.

  Capabilities are deliberately narrow: only `supports_custom_colors` is
  declared, so an organiser can tune the accent without being able to drop a
  video or photo behind the brand canvas.
  """

  use Gettext, backend: TymeslotWeb.Gettext

  @behaviour TymeslotWeb.Themes.Core.Behaviour

  alias TymeslotWeb.Themes.Wertkurs.Meeting.{Cancel, CancelConfirmed, Reschedule}

  alias TymeslotWeb.Themes.Wertkurs.Scheduling.Components.{
    BookingComponent,
    ConfirmationComponent,
    OverviewComponent,
    ScheduleComponent
  }

  @impl TymeslotWeb.Themes.Core.Behaviour
  def states do
    %{
      overview: %{step: 1, next: :schedule, prev: nil},
      schedule: %{step: 2, next: :booking, prev: :overview},
      booking: %{step: 3, next: :confirmation, prev: :schedule},
      confirmation: %{step: 4, prev: :booking}
    }
  end

  @impl TymeslotWeb.Themes.Core.Behaviour
  def css_file, do: "/assets/scheduling-theme-wertkurs.css"

  @impl TymeslotWeb.Themes.Core.Behaviour
  def components do
    %{
      overview: OverviewComponent,
      schedule: ScheduleComponent,
      booking: BookingComponent,
      confirmation: ConfirmationComponent
    }
  end

  @impl TymeslotWeb.Themes.Core.Behaviour
  def live_view_module, do: TymeslotWeb.Themes.Wertkurs.Scheduling.Live

  @impl TymeslotWeb.Themes.Core.Behaviour
  def theme_config do
    %{
      name: "wertkurs",
      description:
        dgettext(
          "dashboard_appearance",
          "Bright, calm brand theme with a week-at-a-glance schedule step and a numbered 4-step flow."
        ),
      preview_image: "/images/ui/theme-previews/wertkurs-theme-preview.webp",
      flow_steps: 4,
      design_system: :wertkurs,
      supports_duration_selection: true,
      supports_inline_booking: false
    }
  end

  @impl TymeslotWeb.Themes.Core.Behaviour
  def validate_theme do
    required_components = [:overview, :schedule, :booking, :confirmation]

    missing_components =
      Enum.filter(required_components, fn component ->
        not Code.ensure_loaded?(components()[component])
      end)

    if Enum.empty?(missing_components) do
      :ok
    else
      {:error, "Missing components: #{inspect(missing_components)}"}
    end
  end

  @impl TymeslotWeb.Themes.Core.Behaviour
  def initial_state_for_action(live_action) do
    case live_action do
      :index -> :overview
      :overview -> :overview
      :schedule -> :schedule
      :booking -> :booking
      :confirmation -> :confirmation
      _other -> :overview
    end
  end

  @impl TymeslotWeb.Themes.Core.Behaviour
  def supports_feature?(feature) do
    case feature do
      :duration_selection -> true
      :inline_booking -> false
      :step_navigation -> true
      :step_rail -> true
      :week_strip -> true
      :custom_colors -> true
      :video_background -> false
      _other -> false
    end
  end

  @impl TymeslotWeb.Themes.Core.Behaviour
  def render_meeting_action(assigns, action) do
    case action do
      :reschedule -> Reschedule.render(assigns)
      :cancel -> Cancel.render(assigns)
      :cancel_confirmed -> CancelConfirmed.render(assigns)
      _other -> raise "Unsupported meeting action: #{action}"
    end
  end

  @impl TymeslotWeb.Themes.Core.Behaviour
  defdelegate render_poll_action(assigns), to: TymeslotWeb.Themes.Wertkurs.Poll.Voting, as: :render
end
