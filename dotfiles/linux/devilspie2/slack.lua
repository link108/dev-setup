-- Slack has its own header (search, history arrows), so drop the Cinnamon title bar like Discord
if get_window_class() == "com.slack.Slack" then
  undecorate_window()
end
