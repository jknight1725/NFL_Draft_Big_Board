# frozen_string_literal: true

require 'tty-prompt'
require 'colorize'

class Draftee
  attr_reader :name, :position, :school
  attr_accessor :comparisons, :points

  def initialize(args)
    @name = args[:name]
    @position = args[:position]
    @school = args[:school]
    @points = 1
    @comparisons = {}
  end

  def compare(other)
    comparisons[other] = true
    other.comparisons[self] = true
    result = TTY::Prompt.new.select("#{name} or #{other.name}", [name, other.name])
    result == name ? self.points += other.points : other.points += self.points
  end

  def to_s
    name.to_s
  end
end

def next_comparison(player, draft_list)
  d = draft_list - [player]
  d.find { |p2| !player.comparisons[p2] }
end

def sort_by_preference(players)
  big_board = []
  until players.empty?
    p1 = players.sample
    p2 = next_comparison(p1, players)
    p2 ? p1.compare(p2) : big_board.append(players.delete(p1))
  end
  big_board.sort_by(&:points).reverse
end

def generate_draft_list
  draft_list = IO.readlines('top_100.txt')
  draft_list.map! { |data| data.split(', ') }
  draft_list.map! do |player|
    Draftee.new(name: player[0],
                position: player[1],
                school: player[2])
  end
  draft_list
end

def group_by_position(draft_list)
  positions = Hash.new([])
  draft_list.each { |player| positions[player.position] += [player] }
  positions.transform_keys(&:to_sym)
end

def select_position(position_list)
  TTY::Prompt.new.select('Pick a position', [position_list.keys])
end

top_100 = generate_draft_list
position_groups = group_by_position(top_100)
selection = select_position(position_groups)
sorted_position_group = sort_by_preference(position_groups[selection.to_sym])
sorted_position_group.each_with_index { |v, i| puts "#{i + 1}\t#{v}" }
