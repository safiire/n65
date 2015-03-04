module Assembler6502

  class SymbolTable

    #####  Custom Exceptions
    class InvalidScope < StandardError; end
    class UndefinedSymbol < StandardError; end
    class CantExitScope < StandardError; end


    ####
    ##  Initialize a symbol table that begins in global scope
    def initialize
      @symbols = {
        :global => {}
      }
      @anonymous_scope_number = 0
      @scope_stack = [:global]
    end


    ####
    ##  Define a new scope, which can be anonymous or named
    ##  and switch into that scope
    def enter_scope(name = nil)
      name = generate_name if name.nil? 
      name = name.to_sym
      scope = current_scope
      if scope.has_key?(name)
        path_string = generate_scope_path(path_ary)
        fail(InvalidScope, "Scope: #{path_string} already exists")
      end
      scope[name] = {}
      @scope_stack.push(name)
    end


    ####
    ##  Exit the current scope
    def exit_scope
      if @scope_stack.size == 1
        fail(CantExitScope, "You cannot exit global scope")
      end
      @scope_stack.pop
    end


    ####
    ##  Define a symbol in the current scope
    def define_symbol(symbol, value)
      scope = current_scope
      scope[symbol.to_sym] = value
    end


    ####
    ##  Resolve symbol to a value, for example:
    ##  scope1.scope2.variable
    ##  It is not nessessary to specify the root scope :global
    ##  You can just address anything by name in the current scope
    ##  To go backwards in scope you need to write the full path
    ##  like global.sprite.x or whatever
    def resolve_symbol(name)
      value = if name.include?('.')
        path_ary = name.split('.').map(&:to_sym)
        symbol = path_ary.pop
        path_ary.shift if path_ary.first == :global
        scope = retreive_scope(path_ary)
        scope[symbol]
      else
        scope = current_scope
        scope[name.to_sym]
      end

      if value.nil?
        fail(UndefinedSymbol, name)
      end
      value
    end


    ####
    ##  Export the symbol table as YAML
    def export_to_yaml
      @symbols.to_yaml.gsub(/(\d+)$/) do |match|
        integer = match.to_i
        sprintf("0x%.4X", integer)
      end
    end


    private

    ####
    ##  A bit more clearly states to get the current scope
    def current_scope
      retreive_scope
    end


    ####
    ##  Retrieve a reference to a scope, current scope by default
    def retreive_scope(path_ary = @scope_stack)
      path_ary = path_ary.dup
      path_ary.unshift(:global) unless path_ary.first == :global

      path_ary.inject(@symbols) do |scope, path_component|
        new_scope = scope[path_component.to_sym]

        if new_scope.nil?
          path_string = generate_scope_path(path_ary)
          message = "Resolving scope: #{path_string} failed at #{path_component}"
          fail(InvalidScope, message) if new_scope.nil?
        end

        new_scope
      end
    end


    ####
    ##  Generate a scope path from an array
    def generate_scope_path(path_ary)
      path_ary.join('.')
    end


    ####
    ##  Generate an anonymous scope name
    def generate_name
      @anonymous_scope_number += 1
      "anonymous_#{@anonymous_scope_number}"
    end

  end

end
