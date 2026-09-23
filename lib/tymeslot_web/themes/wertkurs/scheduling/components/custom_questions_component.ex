defmodule TymeslotWeb.Themes.Wertkurs.Scheduling.Components.CustomQuestionsComponent do
  @moduledoc """
  The conditional `:questions` step — one question per card, with a segmented
  progress row (hidden when there is only one question).

  The chrome is wertkurs; the fields and the event handling are the shared
  engine's, so a new field type appears here without a theme change.
  """
  use TymeslotWeb, :live_component
  use Gettext, backend: TymeslotWeb.Gettext

  alias TymeslotWeb.Themes.Shared.CustomQuestions.Events
  alias TymeslotWeb.Themes.Shared.CustomQuestions.Inputs.Renderer, as: InputRenderer
  alias TymeslotWeb.Themes.Wertkurs.Shared.StepRail

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, Map.drop(assigns, [:flash, :socket]))}
  end

  @impl Phoenix.LiveComponent
  defdelegate handle_event(event, params, socket), to: Events

  @impl Phoenix.LiveComponent
  def render(assigns) do
    assigns = Events.assign_render_state(assigns)

    ~H"""
    <div class="scheduling-box" data-locale={@locale}>
      <div class="slide-container">
        <div class="slide active">
          <div class="slide-content questions-slide">
            <StepRail.step_rail current_state={:questions} questions?={true} />

            <div
              :if={@total > 1}
              class="wertkurs-progress-dots"
              role="progressbar"
              aria-label={dgettext("booking", "Question %{n} of %{m}", n: @index + 1, m: @total)}
              aria-valuenow={@index + 1}
              aria-valuemin={1}
              aria-valuemax={@total}
            >
              <span
                :for={i <- 0..(@total - 1)}
                aria-hidden="true"
                class={[
                  "wertkurs-progress-dot",
                  i == @index && "is-active",
                  i < @index && "is-done"
                ]}
              />
            </div>

            <h2 class="slide-title">{@definition["label"]}</h2>

            <p :if={@definition["help_text"]} class="wertkurs-questions-help">
              {@definition["help_text"]}
            </p>

            <InputRenderer.render definition={@definition} value={@value} myself={@myself} />

            <p :if={@error} class="wertkurs-form-error">{@error}</p>

            <div class="slide-actions horizontal">
              <button type="button" class="prev-button" phx-click="back" phx-target={@myself}>
                <span class="custom-question-cta-nowrap">← {dgettext("booking", "back")}</span>
              </button>
              <button type="button" class="submit-button" phx-click="next" phx-target={@myself}>
                <span class="custom-question-cta-nowrap">
                  <%= if @last? do %>
                    {dgettext("booking", "Continue")} →
                  <% else %>
                    {dgettext("booking", "next")} →
                  <% end %>
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
