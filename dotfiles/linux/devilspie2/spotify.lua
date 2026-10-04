-- Spotify draws its own controls, so drop the Cinnamon title bar (like ghostty's gtk-titlebar = false)
if get_window_class() == "Spotify" then
  undecorate_window()
end
