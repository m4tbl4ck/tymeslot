defmodule TymeslotWeb.Themes.Wertkurs.Scheduling.Live do
  @moduledoc """
  wertkurs scheduling LiveView. All common callbacks (mount, handle_params,
  handle_info, language/booking/scheduling events) come from the shared
  `SchedulingLive` macro; this module only renders.

  Week navigation is handled by the shared schedule events, so no
  `handle_theme_schedule_event/3` override is needed.
  """
  use TymeslotWeb.Themes.Shared.SchedulingLive, theme_id: "3"

  alias TymeslotWeb.Themes.Shared.Components.AwaitingPayment
  alias TymeslotWeb.Themes.Wertkurs.Scheduling.Wrapper, as: WertkursThemeWrapper

  alias TymeslotWeb.Themes.Wertkurs.Scheduling.Components.{
    BookingComponent,
    ConfirmationComponent,
    CustomQuestionsComponent,
    OverviewComponent,
    ScheduleComponent
  }

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <WertkursThemeWrapper.wertkurs_wrapper
      custom_css={assigns[:custom_css]}
      theme_customization={assigns[:theme_customization]}
      locale={assigns[:locale]}
      language_dropdown_open={assigns[:language_dropdown_open]}
      current_state={assigns[:current_state]}
      organizer_user_id={@organizer_user_id}
      should_show_branding={assigns[:should_show_branding]}
    >
      <%= if assigns[:scheduling_error_message] do %>
        <.live_component
          module={ErrorComponent}
          id="scheduling-error"
          message={@scheduling_error_message}
          reason={assigns[:scheduling_error_reason]}
        />
      <% else %>
        <%= case assigns[:current_state] || :overview do %>
          <% :overview -> %>
            <.live_component module={OverviewComponent} id="overview-step" {assigns} />
          <% :schedule -> %>
            <.live_component module={ScheduleComponent} id="schedule-step" {assigns} />
          <% :questions -> %>
            <.live_component module={CustomQuestionsComponent} id="questions-step" {assigns} />
          <% :booking -> %>
            <.live_component module={BookingComponent} id="booking-step" {assigns} />
          <% :awaiting_payment -> %>
            <AwaitingPayment.awaiting_payment checkout_url={@awaiting_payment_checkout_url} />
          <% :confirmation -> %>
            <.live_component module={ConfirmationComponent} id="confirmation-step" {assigns} />
          <% _ -> %>
            <.live_component module={OverviewComponent} id="overview-step" {assigns} />
        <% end %>
      <% end %>
    </WertkursThemeWrapper.wertkurs_wrapper>
    """
  end
end
