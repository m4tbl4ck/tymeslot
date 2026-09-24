defmodule TymeslotWeb.Themes.Wertkurs.Scheduling.Wrapper do
  @moduledoc """
  Visual shell for the wertkurs theme: the brand canvas (light field + grain +
  a single mint horizon), the organiser's custom colour overrides, and the
  branding footer. There is deliberately no language switcher — the page
  language is resolved by `LocalePlug` (`?locale=`, `Accept-Language`, then the
  instance booking default).

  The theme declares no video/image/gradient background capability, so the
  canvas is fixed — the only customisation that reaches here is the colour
  `custom_css` block, which arrives ready to emit.
  """
  use Phoenix.Component

  import TymeslotWeb.Themes.Shared.Customization.Helpers

  attr :theme_customization, :map, default: nil
  attr :custom_css, :string, default: nil
  attr :locale, :string, default: nil
  attr :current_state, :atom, default: nil
  attr :language_dropdown_open, :boolean, default: nil
  attr :organizer_user_id, :integer, default: nil
  attr :should_show_branding, :boolean, default: false
  attr :show_language_switcher, :boolean, default: nil
  slot :inner_block, required: true

  @doc "Renders the wertkurs theme wrapper."
  @spec wertkurs_wrapper(map()) :: Phoenix.LiveView.Rendered.t()
  def wertkurs_wrapper(assigns) do
    # Derives @has_video_background, @video_poster, @show_language_switcher
    assigns = prepare_wrapper_assigns(assigns)

    ~H"""
    <div class="wertkurs-theme-wrapper theme-3" data-locale={assigns[:locale]}>
      <%= if assigns[:custom_css] && assigns[:custom_css] != "" do %>
        <style type="text/css">
          :root {
            <%= Phoenix.HTML.raw(@custom_css) %>
          }
        </style>
      <% end %>

      <div class="wertkurs-canvas" aria-hidden="true"></div>

      <div class="wertkurs-stage">
        <div class="content-area">
          <%!-- No language switcher: every visitor is German-speaking. The
          page language comes from ?locale=de (the embed passes it), the
          browser's Accept-Language, or the instance booking default. --%>
          {render_slot(@inner_block)}
        </div>

        {TymeslotWeb.Layouts.render_theme_extensions(assigns)}
      </div>
    </div>
    """
  end
end
