defmodule TymeslotWeb.Themes.Wertkurs.Shared.StepRail do
  @moduledoc """
  Numbered step rail shown at the top of every pre-confirmation step.

  Numbered, step-by-step progress is a wertkurs signature ("Schritt 1 / 2 / 3"):
  it tells the booker how much is left, which is the whole point of the brand's
  "no surprises" promise. The questions step only appears in the rail when the
  meeting type actually has custom fields, matching
  `StateMachineHelpers.states_for/1`.
  """
  use Phoenix.Component
  use Gettext, backend: TymeslotWeb.Gettext

  attr :current_state, :atom, required: true
  attr :questions?, :boolean, default: false

  @spec step_rail(map()) :: Phoenix.LiveView.Rendered.t()
  def step_rail(assigns) do
    assigns = assign(assigns, :steps, steps(assigns.questions?))

    ~H"""
    <ol class="step-rail" aria-label={dgettext("booking", "Booking steps")}>
      <li
        :for={{{state, label}, index} <- Enum.with_index(@steps)}
        class={[
          "step-rail_item",
          state == @current_state && "is-current",
          done?(state, @current_state, @steps) && "is-done"
        ]}
        aria-current={state == @current_state && "step"}
      >
        <span class="step-rail_dot">{index + 1}</span>
        <span class="step-rail_label">{label}</span>
        <span :if={index + 1 < length(@steps)} class="step-rail_line" aria-hidden="true"></span>
      </li>
    </ol>
    """
  end

  defp steps(questions?) do
    before = [
      {:overview, dgettext("booking", "Option")},
      {:schedule, dgettext("booking", "Time")}
    ]

    questions =
      if questions?, do: [{:questions, dgettext("booking", "Questions")}], else: []

    after_questions = [
      {:booking, dgettext("booking", "Details")},
      {:confirmation, dgettext("booking", "Done")}
    ]

    before ++ questions ++ after_questions
  end

  defp done?(state, current_state, steps) do
    index_of(steps, state) < index_of(steps, current_state)
  end

  defp index_of(steps, state) do
    Enum.find_index(steps, fn {s, _label} -> s == state end) || 0
  end
end
