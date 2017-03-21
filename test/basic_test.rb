lib = File.expand_path("../../lib", __FILE__)
$:.unshift lib unless $:.include?(lib)

require "test/unit"
require "basic/interpreter"
require "stringio"

class BasicTest < Test::Unit::TestCase

  def capture(string)
    old_stdin, old_stdout = $stdin, $stdout
    lines = string.strip.split(/\n/).map{ |s| s.strip } + %w[EXIT]
    cmd = lambda{ lines.shift }
    output = ""
    $stdout = StringIO.new(output)
    Basic::Interpreter.run(cmd)
    $stdin, $stdout = old_stdin, old_stdout
    raise output if output.include?("SYNTAX ERROR")
    output.sub(/^READY\n/, "").strip
  end

  def blockquote(string)
    string.strip.gsub(/^\s+/, "")
  end

  def test_negative_numbers
    output = capture <<-'END'
      10 LET A=-1
      20 PRINT A
      RUN
    END
    assert_match /-1/,output
  end

  def test_positive_step_in_FOR_loop
    output = capture <<-'END'
      10 FOR I=1 TO 4 STEP 2
      20 PRINT I
      30 NEXT I
      RUN
    END
    assert_match /1\n3/, output
  end

  def test_negative_step_in_FOR_loop
    output = capture <<-'END'
      10 FOR I=4 TO 1 STEP -2
      20 PRINT I
      30 NEXT I
      RUN
    END
    assert_match /4\n2/, output
  end

  def test_should_count_up_in_FOR_loop
    output = capture <<-'END'
      10 FOR I=1 TO 4
      20 PRINT I
      30 NEXT I
      RUN
    END
    assert_match /1\n2\n3\n4/, output
  end

  def test_for_loop_on_one_line
    output = capture <<-'END'
      10 FOR I=1 TO 4: PRINT I: NEXT I
      RUN
    END
    assert_match /1\n2\n3\n4/, output
  end

  def test_greater_than
    output = capture <<-'END'
      10 LET I = 4
      20 IF I>3 THEN PRINT "GREATER THAN 3"
      25 IF I>4 THEN PRINT "GREATER THAN 4"
      30 IF I>5 THEN PRINT "GREATER THAN 5"
      RUN
    END
    assert_match /GREATER THAN 3/, output
  end

  def test_precedence
    output = capture <<-'END'
      10 LET D = 0.4
      20 LET D1 = 0.5
      30 IF D-D1>0 THEN PRINT "FALSE"
      40 IF D1-D>0 THEN PRINT "TRUE"
      RUN
    END
    assert_match(/TRUE/, output)
    assert_no_match(/FALSE/, output)
  end

  def test_parse_floats
    output = capture <<-'END'
      10 LET A = .4
      20 IF A = 0.4 THEN PRINT "HELLO"
      RUN
    END
    assert_match("HELLO", output)
  end

  def test_string_equal
    output = capture <<-'END'
      10 LET A$ = "H" + "A"
      20 IF A$ = "HA" THEN PRINT "HELLO"
      RUN
    END
    assert_match /HELLO/,output
  end

  def test_if_else
    output = capture <<-'END'
      10 LET I = 4
      20 IF I>3 THEN PRINT "GREATER THAN 3" ELSE PRINT "NOT GREATER THAN 3"
      25 IF I>4 THEN PRINT "GREATER THAN 4" ELSE PRINT "NOT GREATER THAN 4"
      30 IF I>5 THEN PRINT "GREATER THAN 5" ELSE PRINT "NOT GREATER THAN 5"
      RUN
    END
    assert_equal ["GREATER THAN 3","NOT GREATER THAN 4","NOT GREATER THAN 5"].join("\n"), output
  end

  def test_less_than_or_equal_to
    output = capture <<-'END'
      10 LET I = 4
      20 IF I<=3 THEN PRINT "LTE THAN 3"
      25 IF I<=4 THEN PRINT "LTE THAN 4"
      30 IF I<=5 THEN PRINT "LTE THAN 5"
      RUN
    END
    assert_match /LTE THAN 4\nLTE THAN 5/, output
  end

  def test_greater_than_or_equal_to
    output = capture <<-'END'
      10 LET I = 4
      20 IF I>=3 THEN PRINT "GTE THAN 3"
      25 IF I>=4 THEN PRINT "GTE THAN 4"
      30 IF I>=5 THEN PRINT "GTE THAN 5"
      RUN
    END
    assert_match /GTE THAN 3\nGTE THAN 4/, output
  end

  def test_less_than
    output = capture <<-'END'
      10 LET I = 4
      20 IF I<3 THEN PRINT "LESS THAN 3"
      25 IF I<4 THEN PRINT "LESS THAN 4"
      30 IF I<5 THEN PRINT "LESS THAN 5"
      RUN
    END
    assert_match /LESS THAN 5/, output
  end

  def test_dim_defines_an_array
    output = capture <<-'END'
      10 DIM A(8)
      20 LET B = 1
      30 LET A(B) = 2
      40 PRINT "RESULT ";A(B)
      RUN
    END
    assert_match /RESULT 2/, output
  end

  def test_multidimensional_string_arrays
    output = capture <<-'END'
    10 DIM A$(3,3)
    20 LET A$(1,1) = "A"
    30 LET A$(1,2) = "B"
    40 LET A$(2,2) = "C"
    50 FOR I = 0 TO 2
    60 FOR J = 0 TO 2
    65 IF A$(I,J) = "" THEN PRINT "x"; ELSE PRINT A$(I,J);
    80 NEXT J
    85 PRINT
    90 NEXT I
    RUN
  END
  result = <<END
xxx
xAB
xxC
END
    assert_equal result.chomp, output
  end

  def test_multidimensional_number_arrays
    output = capture <<-'END'
      10 DIM A(3,3)
      20 LET A(1,1) = 3
      30 LET A(1,2) = 3
      40 LET A(2,2) = 3
      50 FOR I = 0 TO 2
      60 FOR J = 0 TO 2
      70 PRINT A(I,J);
      80 NEXT J
      85 PRINT
      90 NEXT I
      RUN
    END
    result = <<END
000
033
003
END
    assert_equal result.chomp, output
  end

  def test_assignment_to_multidimensional_number_arrays
    output = capture <<-'END'
      10 DIM A(3,3)
      20 LET A(1,1) = 3
      30 LET A(1,2) = 3
      40 LET A(2,2) = 3
      45 LET A(2,2) = A(2,2) + 1
      50 FOR I = 0 TO 2
      60 FOR J = 0 TO 2
      70 PRINT A(I,J);
      80 NEXT J
      85 PRINT
      90 NEXT I
      RUN
    END
    result = <<END
000
033
004
END
    assert_equal result.chomp, output
  end

  def test_not_equal_to
    output = capture <<-'END'
      10 LET I = 4
      20 IF I<>3 THEN PRINT "NOT 3"
      25 IF I<>4 THEN PRINT "NOT 4"
      30 IF I<>5 THEN PRINT "NOT 5"
      RUN
    END
    assert_match /NOT 3\nNOT 5/, output
  end

  def test_integer_division_should_result_in_float
    output = capture <<-'END'
      10 LET I=4
      20 LET J=3
      30 PRINT I/J
      RUN
    END
    assert_in_delta 4/3.0,output.to_f,0.0001
  end

  def test_should_list_program
    program = blockquote <<-'END'
      5 REM Comment
      40 PRINT "Verbatim string; has some noise!"
      70 PRINT
      80 LET C$=CHR$(64+INT(RND(1)*26+1))
      90 FOR G=1 TO 4
      100 INPUT G$
      110 IF G$=C$ THEN GOTO 210
      120 IF G$<C$ THEN PRINT "LATER";
      130 IF G$>C$ THEN PRINT "EARLIER";
      140 PRINT " THAN ";G$
    END
    expected = program
    actual = capture([program, "LIST"].join("\n"))
    assert_equal expected, actual, ["---- actual ----", actual, "---- expected ----", expected].join("\n\n")
  end

end
