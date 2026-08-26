module DashboardHelper
  ICON_PATHS = {
    grid: '<path d="m3 9 9-6 9 6v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><path d="M9 22V12h6v10" />',
    package: '<path d="m7.5 4.27 9 5.15" /><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z" /><path d="m3.3 7 8.7 5 8.7-5" /><path d="M12 22V12" />',
    activity: '<path d="M22 12h-4l-3 9L9 3l-3 9H2" />',
    database: '<ellipse cx="12" cy="5" rx="9" ry="3" /><path d="M3 5V19A9 3 0 0 0 21 19V5" /><path d="M3 12A9 3 0 0 0 21 12" />',
    refresh: '<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8" /><path d="M21 3v5h-5" /><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16" /><path d="M3 21v-5h5" />'
  }.freeze

  def sidebar_icon(name)
    content_tag(:svg, xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24",
                fill: "none", stroke: "currentColor", stroke_width: "2",
                stroke_linecap: "round", stroke_linejoin: "round",
                class: "h-4 w-4 shrink-0") do
      raw(ICON_PATHS.fetch(name))
    end
  end

  def nav_default
    "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-sidebar-foreground/70 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground transition-colors"
  end

  def nav_active
    "#{nav_default} bg-sidebar-accent text-sidebar-accent-foreground"
  end

  def nav_inactive
    "#{nav_default} cursor-default opacity-50"
  end
end
