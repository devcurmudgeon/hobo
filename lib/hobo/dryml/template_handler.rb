module Hobo::Dryml

  class TemplateHandler

    def initialize(view)
      @view = view
    end

    def render(src, local_assigns)
      renderer = Hobo::Dryml.page_renderer(@view, local_assigns.keys)
      s = renderer.render_page(@view.assigns["this"] || local_assigns[:this], local_assigns)
      # Important to strip whitespace, or the browser hangs around for ages (FF2)

      s = s.strip
      
      # TODO: Temporary hack to get the dryml metadata comments in the right place
      s.gsub!(/^(.*?)(<!DOCTYPE.*?>).*?(<html.*?>)/m, "\\2\\3\\1") if RAILS_ENV == "development"
    end

  end

end
