defmodule TymeslotWeb.Themes.Wertkurs.Scheduling.Components.BookingComponent do
  @moduledoc """
  Step 3 — the attendee's details, with the chosen slot restated in a mint
  summary strip above the form so nobody has to page back to check it.

  Per-field errors only appear once a field has been blurred; every input pairs
  `phx-debounce="blur"` with `phx-blur="field_blur"`, so validation is one
  round-trip per field rather than one per keystroke.
  """
  use TymeslotWeb, :live_component
  use Gettext, backend: TymeslotWeb.Gettext

  alias Tymeslot.Meetings.Approval
  alias Tymeslot.Timezones
  alias TymeslotWeb.Live.Scheduling.OrganizerHelpers
  alias TymeslotWeb.Live.Shared.FormValidationHelpers
  alias TymeslotWeb.Themes.Shared.BookingLabels
  alias TymeslotWeb.Themes.Shared.Components.ApprovalNotice
  alias TymeslotWeb.Themes.Shared.Components.GuestField
  alias TymeslotWeb.Themes.Shared.GuestBooking
  alias TymeslotWeb.Themes.Shared.LocalizationHelpers
  alias TymeslotWeb.Themes.Shared.SecurityFields
  alias TymeslotWeb.Themes.Wertkurs.Shared.OrganizerHeader
  alias TymeslotWeb.Themes.Wertkurs.Shared.StepRail

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, Map.drop(assigns, [:flash, :socket]))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"booking" => booking_params}, socket) do
    send(self(), {:step_event, :booking, :validate, booking_params})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("field_blur", %{"field" => field_name}, socket) do
    send(self(), {:step_event, :booking, :field_blur, field_name})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("submit", %{"booking" => booking_params}, socket) do
    # Flip to submitting immediately so the button reacts without waiting for
    # the parent round-trip.
    send(self(), {:step_event, :booking, :submit, booking_params})
    {:noreply, assign(socket, :submitting, true)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("back_step", _params, socket) do
    send(self(), {:step_event, :booking, :back_step, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle_guests", _params, socket) do
    send(self(), {:step_event, :booking, :toggle_guests, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_guests", _params, socket) do
    send(self(), {:step_event, :booking, :close_guests, nil})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("guest_input_change", params, socket) do
    send(self(), {:step_event, :booking, :guest_input, params["guest_email"] || ""})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("add_guest", params, socket) do
    send(self(), {:step_event, :booking, :add_guest, params["guest_email"] || ""})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_guest", %{"email" => email}, socket) do
    send(self(), {:step_event, :booking, :remove_guest, email})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="scheduling-box" data-locale={@locale}>
      <div class="slide-container">
        <div class="slide active">
          <div class="slide-content booking-slide">
            <StepRail.step_rail current_state={:booking} questions?={questions?(assigns)} />

            <div class="schedule-header">
              <OrganizerHeader.organizer_header_small
                organizer_profile={@organizer_profile}
                meeting_type={@meeting_type}
                selected_duration={@duration}
              />
            </div>

            <div class="meeting-summary compact">
              <div class="summary-row">
                <div class="summary-item">
                  <.icon name="hero-calendar" class="summary-icon hero-icon hero-icon--md" />
                  <div>
                    <div class="summary-value">{LocalizationHelpers.format_date(@selected_date)}</div>
                    <div class="summary-label">
                      {@selected_time || dgettext("booking", "No time selected")}
                    </div>
                  </div>
                </div>
                <div class="summary-item">
                  <.icon name="hero-globe-alt" class="summary-icon hero-icon hero-icon--md" />
                  <div>
                    <div class="summary-value">
                      {Timezones.format(@user_timezone || "Europe/Berlin")}
                    </div>
                    <div class="summary-label">
                      <%= if @meeting_type do %>
                        {LocalizationHelpers.format_duration(@meeting_type.duration_minutes)}
                      <% else %>
                        {LocalizationHelpers.format_duration(@selected_duration)}
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <.form
              :let={f}
              for={@form}
              phx-submit="submit"
              phx-change="validate"
              phx-target={@myself}
              data-testid="booking-form"
              class="booking-form"
              as={:booking}
              id="booking-form"
              {SecurityFields.recaptcha_form_attrs("booking_form", "booking")}
            >
              <SecurityFields.honeypot_field id_prefix="booking" param_root="booking" />

              <.input
                field={f[:name]}
                label={dgettext("booking", "name")}
                placeholder={dgettext("booking", "enter_full_name")}
                errors={FormValidationHelpers.field_errors(@validation_errors, :name)}
                phx-debounce="blur"
                phx-blur="field_blur"
                phx-value-field="name"
                phx-target={@myself}
              />

              <.input
                field={f[:email]}
                type="email"
                label={dgettext("booking", "email")}
                placeholder={dgettext("booking", "enter_email")}
                errors={FormValidationHelpers.field_errors(@validation_errors, :email)}
                phx-debounce="blur"
                phx-blur="field_blur"
                phx-value-field="email"
                phx-target={@myself}
              />

              <.input
                field={f[:message]}
                type="textarea"
                rows={4}
                label={dgettext("booking", "message_optional")}
                placeholder={dgettext("booking", "add_details")}
                errors={FormValidationHelpers.field_errors(@validation_errors, :message)}
                phx-debounce="blur"
                phx-blur="field_blur"
                phx-value-field="message"
                phx-target={@myself}
              />

              <SecurityFields.recaptcha_token_field id_prefix="booking" param_root="booking" />
            </.form>

            <GuestField.guest_field
              :if={GuestBooking.guests_allowed?(assigns)}
              guest_emails={@guest_emails}
              guest_input={@guest_input}
              guest_error={@guest_error}
              guests_open={@guests_open}
              max_guests={@max_guests}
              target={@myself}
            />

            <SecurityFields.recaptcha_notice_block />

            <ApprovalNotice.block
              :if={Approval.required?(@meeting_type)}
              organizer_name={
                BookingLabels.organizer_display_name(@organizer_profile, @username_context)
              }
              payment_required={@meeting_type.payment_required}
              stage={:before}
            />

            <div class="slide-actions horizontal">
              <button
                type="button"
                class="prev-button"
                phx-click="back_step"
                phx-target={@myself}
                data-testid="back-step"
                disabled={@submitting}
              >
                ← {dgettext("booking", "back")}
              </button>
              <button
                type="submit"
                form="booking-form"
                class="submit-button"
                data-testid="submit-booking"
                disabled={@submitting || !OrganizerHelpers.form_valid?(@form)}
              >
                <%= if @submitting do %>
                  <svg
                    class="loading-spinner icon-sm"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="loading-spinner-track"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    >
                    </circle>
                    <path
                      class="loading-spinner-path"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    >
                    </path>
                  </svg>
                  <span>{dgettext("booking", "Verifying...")}</span>
                <% else %>
                  {BookingLabels.submit_label(
                    @is_rescheduling,
                    @meeting_type,
                    dgettext("booking", "submit")
                  )}
                <% end %>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp questions?(assigns) do
    Enum.any?(
      [assigns[:custom_field_definitions], assigns[:custom_fields_snapshot]],
      &(is_list(&1) and &1 != [])
    )
  end
end
