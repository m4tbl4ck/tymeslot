defmodule TymeslotWeb.Themes.Wertkurs.Poll.Voting do
  @moduledoc """
  Public poll voting page in the wertkurs shell. The poll content itself is the
  shared, theme-neutral component; styling comes from this theme's modules.
  """
  use Phoenix.Component
  use Gettext, backend: TymeslotWeb.Gettext

  alias TymeslotWeb.Themes.Shared.PollVotingComponents
  alias TymeslotWeb.Themes.Wertkurs.Scheduling.Wrapper

  attr :theme_customization, :map, required: true
  attr :custom_css, :string, required: true
  attr :locale, :string, required: true
  attr :language_dropdown_open, :boolean, required: true
  attr :poll, :map, required: true
  attr :tallies, :map, required: true
  attr :voting_open, :boolean, required: true
  attr :participant, :map, default: nil

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <Wrapper.wertkurs_wrapper
      theme_customization={@theme_customization}
      custom_css={@custom_css}
      locale={@locale}
      language_dropdown_open={@language_dropdown_open}
      show_language_switcher={true}
    >
      <div class="scheduling-box poll-voting-page wertkurs-poll-voting">
        <div class="slide-container">
          <div class="slide active">
            <div class="slide-content">
              <PollVotingComponents.poll_content
                poll={@poll}
                tallies={@tallies}
                voting_open={@voting_open}
                participant={@participant}
              />
            </div>
          </div>
        </div>
      </div>
    </Wrapper.wertkurs_wrapper>
    """
  end
end
