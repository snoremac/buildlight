require 'announce'

class LightController

  COLOUR_MAP = {
    :default => [:blue],
    :failed => [:red],
    :aborted => [:yellow],
    :passed => [:green],
    :unknown => [:blue],
    :stopped => [:off]
  }

  TRANSITION_MAP = Hash.new(Hash.new({})) # two-level-deep default hash
  TRANSITION_MAP[:failure] = {:claimed => 'has been claimed.', :success => "has been fixed.", :failure => 'has (ADVERB)failed again and requires attention.'}
  TRANSITION_MAP[:success] = {:failure => 'has failed and requires attention.', :success => 'was successful.'}
  TRANSITION_MAP[:claimed] = {:failure => TRANSITION_MAP[:failure][:failure], :success => 'has been fixed.', :claimed => 'has failed again.'}

  ADJECTIVES = [ '', 'Wonderful.', 'Fantastic.', 'Brilliant.', 'Super.', 'Smashing.' ]
  ADVERBS = [ '', 'amazingly ', 'sadly ', 'unfortunately ', 'epic ' ]

  def initialize light, host, projects
    @light = light
    @host = host
    @projects = projects
    @keep_alive = true
    @state = :default
    @build_num = nil
    puts "light ##{light} => monitoring #{projects.inspect}"
    start_light_updater
  end

  def update_status
    begin
      project_statuses = get_all_projects_status @host, @projects
      if project_statuses.empty?
        error
      else
        update project_statuses
      end
    rescue Exception => e
      @current_colours = COLOUR_MAP[:unknown].clone
      set_light_color @current_colours
      'Error: (lights should be blue right about now...)'
      puts e.inspect
      puts e.backtrace
    end
  end

  def reset
    @current_colours = COLOUR_MAP[:default].clone
  end

  def stop
    @keep_alive = false
    @current_colours = COLOUR_MAP[:stopped].clone
    set_light_color @current_colours
    @light.close
  end

  def update project_statuses
    previous_colours = @current_colours
    previous_state = @state
    previous_build_num = @build_num

    any_status = lambda do |state|
      project_statuses.collect(&:state).include? state
    end

    if any_status.call 'failure'
      @state = :failed
    elsif any_status.call 'aborted'
      @state = :aborted
    elsif any_status.call 'success'
      @state = :passed
    else
      @state = :unknown
    end

    @build_num = project_statuses.first.build_number
    @current_colours = COLOUR_MAP[@state].clone
    if project_statuses.collect(&:building).include? ['true']
		@current_colours += [:off]
    end
    project_description = project_statuses.first.name
    announce_transition(previous_state, @state, previous_build_num, @build_num, project_description)

    puts "Colours changed from #{previous_colours.inspect} to #{@current_colours.inspect}"
  end

  def announce_transition(previous_state, current_state, previous_build_num, current_build_num, project_description)
    puts "#{project_description}: announcing transition from #{previous_state} to #{current_state}, build #{previous_build_num}->#{current_build_num}"
    if project_description =~ QUIET_SUCCESS and previous_state == current_state
      puts "project matches QUIET_SUCCESS - not announcing"
      return
    end
    transition = TRANSITION_MAP[previous_state][current_state]
    if transition.nil?
      puts "no transition description"
      return
    end
    if transition.empty?
      puts "empty transition description"
      return
    end
    if (previous_build_num == current_build_num && current_state == previous_state)
      puts "no state change and same build"
      return
    end

    transition_description = "#{project_description} #{transition}"
    if current_state == :failure
      transition_description += " #{ADJECTIVES[rand(ADJECTIVES.length)]}"
    end
    transition_description = transition_description.gsub(/\(ADVERB\)/, ADVERBS[rand(ADVERBS.length)])
    puts "Transition: #{transition_description}"
    Announce.say(transition_description)
  end

  def start_light_updater
    reset
    Thread.new do
      last_colours = nil
      while @keep_alive do
        @current_colours << @current_colours.shift
        colours = @current_colours.first
        if last_colours != colours
          set_light_color colours
          last_colours = colours
        end
        sleep 0.5
      end
      puts "Light Controller exiting"
    end
  end

  def set_light_color colors
    colors = [colors] unless colors.kind_of? Array
    @light.method(colors[0].to_s).call
  end

end

