require 'rubygems'
require 'bundler/setup'
#if(RUBY_PLATFORM == 'java')
#  require 'pg'
#end
require 'active_record'
require 'active_record/migration'
require 'benchmark'
require 'acts_as_sane_tree'
require 'minitest/autorun'

ActiveRecord::Base.establish_connection(
  :adapter => 'postgresql',
  :database => 'tree_test',
  :username => 'postgres'
)

class Node < ActiveRecord::Base
  acts_as_sane_tree :order => :position
  validates_uniqueness_of :name
  validates_uniqueness_of :parent_id, :scope => :id
  validates_uniqueness_of :position, :scope => :parent_id
end

class NodeSetup < ActiveRecord::Migration
  class << self
    def up
      create_table :nodes do |t|
        t.text :name
        t.integer :parent_id
        t.integer :position
      end
      add_index :nodes, [:parent_id, :id], :unique => true
    end
  end
end

# Quick and dirty database scrubbing
if(Node.table_exists?)
  ActiveRecord::Base.connection.execute "drop schema public cascade"
  ActiveRecord::Base.connection.execute "create schema public"
end

NodeSetup.up

# Create three root nodes with 50 descendants
# Descendants should branch randomly

nodes = []
random_positions = (0..50).to_a.sort{ rand() - 0.5 }

3.times do |i|
  nodes[i] = []
  parent = Node.create(:name => "root_#{i}", :position => random_positions[i])
  50.times do |j|
    node = Node.new(:name => "node_#{i}_#{j}", :position => random_positions[j])
    _parent = nodes[i][rand(nodes[i].size)] || parent
    node.parent_id = _parent.id
    node.save
    nodes[i] << node
  end
end

#give a more predictable root node
parent = Node.create(:name => "root_static", :position => random_positions[4])
20.times do |j|
  node = Node.create(:name => "node_static_#{j}", :position => random_positions[j], :parent_id => parent.id)
end

