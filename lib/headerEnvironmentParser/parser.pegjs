{
  var minindention = 1;
  var isCoffee = false;

  function values(values) {
    function convertValue(value) {
      var temp = null;
      value = ('' + value).trim()

      /* Booleans */
      if (value === 'true') {
        return true;
      }
      if (value === 'false') {
        return false;
      }

      /* Numbers */
      temp = parseInt(value);
      if (temp + '' === value) {
        return temp;
      }
      temp = parseFloat(value);
      if (temp + '' === value) {
        return temp;
      }

      /* Arrays */
      if (/,/.test(value)) {
        return value.split(',').map(convertValue);
      }

      /* Strings */
      return value
    }

    return values.split('|').map(convertValue);
  }
}

start
  = whatever environment:environment? whatever
  { return environment; }

environment "Environment"
  = opening_comment environment_start definitions:definitions closing_comment
  { return definitions; }

environment_start
  = comment_line_start space:(!environment_indicator s:whitespace { return s;})* start:environment_indicator linebreak
  { minindention = space.join('').length + 1; return start; }

definitions
  = d:definition* { return d.filter(function(val) { return typeof val === 'object'; }); }

definition "Definition"
  = environment_comment { return false; }
  / comment_line_start indention method:method_name seperator values:values linebreak
  { return [method, values]; }
  / empty_comment_line { return false; }

empty_comment_line
  = comment_line_start whitespace* linebreak

environment_comment
  = comment_line_start indention "#" (!linebreak any_char)* linebreak

method_name "Method Name"
  = method:(!seperator c:any_char { return c; })* { return method.join('').trim(); }

values "Values"
  = v:(!linebreak c:any_char { return c; })* { return values(v.join('')); }

opening_comment "Opening Multi-Line Comment"
  = "/*" (!environment_start any_char)* { isCoffee = false }
  / "###*" (!environment_start any_char)* { isCoffee = true }

closing_comment "Closing Multi-Line Comment"
  = (!"*/" any_char)* "*/" & { return !isCoffee }
  / (!"###" any_char)* "###" & { return isCoffee }

indention "indention"
  = space:whitespace* & {
    var amount = space.length;
    if (amount > minindention) {
      minindention = amount;
    }
    return amount >= minindention
  }

comment_line_start "Comment Line Start"
  =  (!"*" whitespace)* "*"

any_char
  = .

seperator
  = ":"

space
  = [ ]

whitespace
  = space
  / [\t]

environment_indicator
  = "karma environment"i

linebreak "Linebreak"
  = [\n]

whatever
  = (!environment any_char)*
