#!/usr/bin/ruby -E UTF-8
# encoding: UTF-8

input = STDIN.readlines
variable_maps = []

operators = ARGV[0].strip.dup.split('|').map { |operator| operator.strip }
operators.each do |operator|
	new_input = []
	tokens = operator.split(/ /)
	case tokens[0]
	when '*'
		# do nothing
	when 'parse'
		if tokens[1].start_with? '"'
			last_pattern_token_index = tokens[2..-1].find_index { |token| token[-1] == '"' and token[-2] != '\\' } + 2 || -1
			original_pattern = tokens[1..last_pattern_token_index].join(' ')[1..-2]
		else
			last_pattern_token_index = 1
			original_pattern = tokens[1]
		end
		pattern = /#{original_pattern.gsub('*', '(.*)')}/
		# tokens[last_pattern_token_index + 1] should be 'as'
		variable_names = tokens[last_pattern_token_index + 2].split(',')
		input.each do |line|
			match_data = line.match(pattern)
			if match_data
				variable_map = {}
				match_data.captures.zip(variable_names) do |value, name|
					variable_map[name] = value
				end
				variable_maps << variable_map
				new_input << line
			end
		end
	when 'where'
		lhs, op, rhs = *tokens[1..3]
		input.zip(variable_maps) do |line, variable_map|
			lhs_value = variable_map[lhs] || eval(lhs)
			rhs_value = variable_map[rhs] || eval(rhs)
			# Use item instead of type to utilize === and case/when
			compare_type = [lhs_value, rhs_value].find { |item| not (String === item) } || nil

			case compare_type
			when String
				lhs_value = lhs_value.to_s
				rhs_value = rhs_value.to_s
			when Fixnum, Bignum, Integer
				begin
					lhs_value = Integer(lhs_value)
					rhs_value = Integer(rhs_value)
				rescue ArgumentError
					# do nothing
				end
			end

			begin
				if eval("#{lhs_value} #{op} #{rhs_value}")
					new_input << line
				end
			rescue
				# do nothing
			end
		end
	when 'count'
		new_input = input.size
	end
	input = new_input
end

puts input
