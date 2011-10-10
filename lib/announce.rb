class Announce
  def self.say(text)
    #`festival --tts <<EOF\n#{text}\n`
    `festival <<EOF\n(voice_nitech_us_clb_arctic_hts)\n(SayText "#{text}")\n(quit)\n`
  end

  def self.passed(build_name)
    say "#{build_name} has passed"
  end
  def self.failed(build_name)
    say "#{build_name} has failed"
  end
end
