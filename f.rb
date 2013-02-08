class IO
  TAIL_BUF_LENGTH = 1 << 16

  def tail(n, offset=0, filter='')
    return [] if n < 1

    seek -TAIL_BUF_LENGTH, SEEK_END

    n = n + offset

    buf = ""
    if (!filter.empty?)
      while buf.scan(filter).length <= n
        t = read(TAIL_BUF_LENGTH)
        buf = t + buf
        seek 2 * -TAIL_BUF_LENGTH, SEEK_CUR
      end
    else
      while buf.count("\n") <= n
        t = read(TAIL_BUF_LENGTH)
        buf = t + buf
        seek 2 * -TAIL_BUF_LENGTH, SEEK_CUR
      end
    end

    i = 0
    o = 0
    lines = []
    buf.split(/\n|\r/).reverse!.each do |l|
      if filter and !l.include? filter
        next
      end

      if (o < offset)
        o += 1
        next
      else
        i += 1
        lines.push(l)
      end

      if i == (n - offset)
        break
      end
    end

    lines
  end
end

def get_filtered_text(filter = 'Notice')
  t = `grep "\|#{filter}\:"`
  p t
end