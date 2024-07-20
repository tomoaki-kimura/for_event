require "ruby2d"
include Ruby2D::DSL

Wait = 18

class Tetromino
  def initialize
    @pat = Array.new(4)
    # 問題:１
    pats = [["11", "11"], ["011", "110"], ["110", "011"]]
    @num = rand(1..pats.size)
    @pat[0] = pats.map {|pt| pt.map {|st| st.chars.map(&:to_i)} }[@num - 1]
    (1..3).each do |i|
      @pat[i] = @pat[i - 1].reverse.transpose #右回転させる
    end
    
    @dir = 0
    @x, @y = 3, 0
  end
  attr_accessor :x, :y
  
  def rotate(n)
    @dir = (@dir + n) % 4
  end
  
  def get
    @pat[@dir].map {|row| row.map {|i| i * @num} }
  end
  
  def width
    @pat[@dir].first.size
  end
  
  def height
    @pat[@dir].size
  end
end

class Field
  Width, Height = 10, 20
  
  Margin = 30
  BlockMargin = 1
  BlockSide = 25
  S = BlockMargin * 2 + BlockSide
  W = Margin * 2 + S * Width
  H = Margin * 2 + S * Height
  attr_accessor :score

  Color = ["#158FAC", "#F1F101", "#2FFF43", "#DF0F0F",
           "#5858FF", "#FFB950", "#FF98F3"]

  #使える色
  # navy blue aqua teal olive green lime yellow orange red brown fuchsia purple maroon white silver gray black
  
  def initialize
    set width: W, height: H, title: "Tetris"
    Rectangle.new x: 0, y: 0, width: W, height: H, color: "gray", z: 0
    Rectangle.new x: Margin, y: Margin,
                  width: W - 2 * Margin, height: H - 2 * Margin,
                  color: "black", z: 0
    
    @blocks = Height.times.map {|y|
      Width.times.map {|x|
        Square.new x: Margin + BlockMargin + S * x,
                   y: Margin + BlockMargin + S * y,
                   size: BlockSide, color: "red", z: 10
        }
      }
    
    @field = @blocks.map {Array.new(Width, 0)}
  end
  
  def render
    Height.times do |y|
      Width.times do |x|
        @blocks[y][x].color = Color[@field[y][x] - 1]
        @field[y][x].nonzero? ? @blocks[y][x].add : @blocks[y][x].remove
      end
    end
  end
  
  def birth
    @piece = Tetromino.new
    collision? ? raise("game over") : write_to_field
  end
  
  def write_to_field
    x, y = @piece.x, @piece.y
    @piece.get.map.with_index {|row, dy|
      row.each_index {|dx| @field[y + dy][x + dx] = row[dx] if row[dx].nonzero?}
    }
  end
  
  def delete_from_field
    x, y = @piece.x, @piece.y
    @piece.get.map.with_index {|row, dy|
      row.each_index {|dx| @field[y + dy][x + dx] = 0 if row[dx].nonzero?}
    }
  end
  
  def one_down
    delete_from_field
    collision_flag = false
    
    @piece.y += 1
    if collision?
      @piece.y -= 1
      collision_flag = true
    end
    write_to_field
    return collision_flag
  end
  
  def collision?
    x, y = @piece.x, @piece.y
    return true if y + @piece.height > Height || x + @piece.width > Width
    @piece.get.map.with_index {|row, dy|
      row.map.with_index {|a, dx| a.nonzero? && @field[y + dy][x + dx].nonzero?}.any?
    }.any?
  end
  
  def delete_blocks
    Height.times do |y|
      if @field[y].all?(&:nonzero?)
        @field.delete_at(y)
        @field.unshift(Array.new(Width, 0))
        return true  
      end
    end
    false
  end
  
  def move(dx)
    delete_from_field
    @piece.x += dx
    @piece.x -= dx if @piece.x < 0 || collision?
    write_to_field
  end
  
  def rotate
    delete_from_field
    @piece.rotate(1)
    @piece.rotate(-1) if collision?
    write_to_field
  end
end


f = Field.new
t = 1
deleting_continues = false    #ブロックを消す作業が終っていなければtrue
collision_flag = false        #これ以上テトロミノが落下できなければtrue
command = nil
wait = Wait

$score = Text.new(
  0,
  x: 250, y: 0,
  style: 'bold',
  size: 20,
  color: 'black',
  z: 10
)

# 問題:2
on :key_down do |event|
  p event.key
  command = case event.key
            when "down"  then "down"
            else nil
            end
end

f.birth
f.render

update do
  unless collision_flag
    case command
    when "left"   then f.move(-1)
    when "right"  then f.move(1)
    when "rotate" then f.rotate
    when "down"   then wait = 2
    end
    command = nil
  end
  
  collision_flag = f.one_down if (t % wait).zero? && !collision_flag    #落下できるならひとつ落下

  #消せる行があるか
  if (deleting_continues || collision_flag) && (t % 30).zero?
    deleting_continues = f.delete_blocks    #消せる行があれば一行消す
    #すべて消し終わったあとの処理
    unless deleting_continues
      wait = Wait
      collision_flag = false
      f.birth
    end
  end
  
  t += 1
  f.render
end

show
