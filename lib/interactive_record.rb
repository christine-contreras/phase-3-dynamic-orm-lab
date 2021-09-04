require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "pragma table_info('#{table_name}')"

        # table_info = DB[:conn].execute(sql)
        # table_info.map do |row|
        #     row["name"]
        # end.compact
        DB[:conn].execute(sql).map do |row|
            row["name"]
        end.compact
    end

    def initialize(options={})
        options.each do |property, value|
        self.send("#{property}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if do |col|
            col == "id"
        end.join(", ")
    end


    def values_for_insert
        self.class.column_names.map do |col_name|
            # getting value for variable name
            "'#{send(col_name)}'" unless send(col_name).nil?
        end.compact.join(", ")
    end


    def save
        sql = <<-SQL
            INSERT INTO #{self.table_name_for_insert}
            (#{self.col_names_for_insert})
            VALUES (#{self.values_for_insert})
        SQL

        DB[:conn].execute(sql)

        self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT * FROM #{self.table_name}
            WHERE name = ?
            LIMIT 1
        SQL

        DB[:conn].execute(sql, name)
    end

    def self.find_by(hash)
        # check if value is a number if it's text change to text formatting
        value = hash.values.first.class == Fixnum ? hash.values.first : "'#{hash.values.first}'" 

        sql = <<-SQL
            SELECT * FROM #{self.table_name}
            WHERE #{hash.keys.first} = #{value}
        SQL

        DB[:conn].execute(sql)

        # value = hash.values.first
        # formatted_value = value.class == Fixnum ? value : "'#{value}'"
        # sql = "SELECT * FROM #{self.table_name} WHERE #{hash.keys.first} = #{formatted_value}"
        # DB[:conn].execute(sql)
    end
  
end