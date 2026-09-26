module ApplicationHelper
  def room_avatar(name, size: :floor)
    hue = name.to_s.each_byte.sum % 360
    shirt = "hsl(#{hue} 72% 52%)"
    hair = "hsl(#{(hue + 40) % 360} 45% 22%)"
    pants = "hsl(#{hue} 28% 24%)"
    tag.svg(viewBox: "0 0 80 140", class: size == :dj ? "block h-16 w-10" : "mx-auto block h-32 w-[4.6rem]", aria: { hidden: true }) do
      safe_join([
        tag.ellipse(cx: 40, cy: 132, rx: 18, ry: 5, fill: "rgba(0,0,0,0.35)"),
        tag.path(d: "M30 78 h20 l8 42 h-12 l-4 -22 -4 22 h-12 z", fill: pants),
        tag.path(d: "M20 50 h40 l10 30 h-60 z", fill: shirt),
        tag.circle(cx: 40, cy: 28, r: 16, fill: "#f3d2b5"),
        tag.path(d: "M24 24 q16 -24 32 2 q-4 10 -32 0z", fill: hair),
        tag.circle(cx: 34, cy: 30, r: 1.7, fill: "#1b1b1b"),
        tag.circle(cx: 46, cy: 30, r: 1.7, fill: "#1b1b1b")
      ])
    end
  end
end
