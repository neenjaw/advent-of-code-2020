def v2_generate_addrs(base_addr, pattern)
  reversed_pattern = pattern.reverse
  reversed_base_addr = base_addr.to_s(2).reverse

  addrs = ['']

  reversed_pattern.chars.each_with_index do |c, idx|
    case c
    when '1'
      addrs.map { |mask| mask << c }
    when '0'
      addrs.map { |mask| mask << (reversed_base_addr[idx] || c) }
    when 'X'
      addrs = addrs.each_with_object([]) do |mask, acc|
        acc << (mask.clone << '1')
        acc << (mask << '0')
      end
    else
      raise ArgumentError, "unknown bit #{c}"
    end
  end

  addrs.map { |mask| mask.reverse.to_i(2) }
end

def v2_handle_mem(mem, mem_instruction, pattern)
  mem_instruction.chomp =~ /mem\[(\d+)\] = (\d+)/
  base_addr = $1.to_i
  value = $2.to_i

  v2_generate_addrs(base_addr, pattern).each do |addr|
    mem[addr] = value
  end
end

acc = { mem: {}, pattern: nil }
ARGF.readlines.each_with_object(acc) do |line, acc|
  acc[:pattern] = line.chomp.partition(' = ').last if line.start_with?('mask')
  v2_handle_mem(acc[:mem], line, acc[:pattern]) if line.start_with?('mem')
end

# puts acc.inspect
puts acc[:mem].values.sum
