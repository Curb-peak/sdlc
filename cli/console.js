const emoji = require("node-emoji");

const getEmoji = module.exports.getEmoji = emoji.get;

const colors = module.exports.colors = {
  Reset: "\x1b[0m",
  Bright: "\x1b[1m",
  Dim: "\x1b[2m",
  Underscore: "\x1b[4m",
  Blink: "\x1b[5m",
  Reverse: "\x1b[7m",
  Hidden: "\x1b[8m",
  Strike: "\x1b[9m",

  // font
  Primary: "\x1b[10m",
  Alternate_1: "\x1b[11m",
  Alternate_2: "\x1b[12m",
  Alternate_3: "\x1b[13m",
  Alternate_4: "\x1b[14m",
  Alternate_5: "\x1b[15m",
  Alternate_6: "\x1b[16m",
  Alternate_7: "\x1b[17m",
  Alternate_8: "\x1b[18m",
  Fraktur: "\x1b[19m",
  Doubly_Underline: "\x1b[20m",
  Normal: "\x1b[21m",
  Not_Italic: "\x1b[22m",
  Underline_Off: "\x1b[23m",
  Blink_Off: "\x1b[24m",
  Inverse_Off: "\x1b[25m",
  Reveal: "\x1b[26m",
  Not_Crossed: "\x1b[27m",
  Reset_Hidden: "\x1b[28m",
  Not_Crossed_2: "\x1b[29m", //???

  FgBlack: "\x1b[30m",
  FgRed: "\x1b[31m",
  FgGreen: "\x1b[32m",
  FgYellow: "\x1b[33m",
  FgBlue: "\x1b[34m",
  FgMagenta: "\x1b[35m",
  FgCyan: "\x1b[36m",
  FgWhite: "\x1b[37m",
  FgWhite1: "\x1b[38m",
  FgWhite2: "\x1b[39m",

  BgBlack: "\x1b[40m",
  BgRed: "\x1b[41m",
  BgGreen: "\x1b[42m",
  BgYellow: "\x1b[43m",
  BgBlue: "\x1b[44m",
  BgMagenta: "\x1b[45m",
  BgCyan: "\x1b[46m",
  BgWhite: "\x1b[47m"
}

module.exports.logHeading =  function log() {
  for (let i = 0; i < arguments.length; i++) {
    console.log(( i === 0 ? getEmoji('the_horns') + ' ' : '') + colors.FgCyan + '%s' + colors.Reset, arguments[i]);
  }
}

module.exports.log =  function log() {
  for (let i = 0; i < arguments.length; i++) {
    console.log(colors.FgCyan + colors.Dim + '%s' + colors.Reset, arguments[i]);
  }
}

module.exports.errorHeading = function error() {
  for (let i = 0; i < arguments.length; i++) {
    console.log(( i === 0 ? getEmoji('skull_and_crossbones') + ' ' : '') + colors.FgRed + '%s' + colors.Reset, arguments[i]);
  }
}

module.exports.error = function error() {
  for (let i = 0; i < arguments.length; i++) {
    console.log(colors.FgRed + colors.Dim + '%s' + colors.Reset, arguments[i]);
  }
}