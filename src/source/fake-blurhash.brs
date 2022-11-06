'' Largely based on the work of Neil Burrows: https://github.com/neilsb

'' call "render(blurhash, width, height) and it will return a uri in tmp://"


function decode83(str as string) as integer
  digitCharacters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~"
  value = 0
  for i = 0 to len(str) - 1
    c = Mid(str, i + 1, 1)
    digit = Instr(0, digitCharacters, c) - 1
    value = value * 83 + digit
  end for

  return value

end function

function isBlurhashValid(blurhash as string) as boolean

  if blurhash = invalid or len(blurhash) < 6
    print "The blurhash string must be at least 6 characters"
    return false
  end if
  sizeFlag = decode83(Mid(blurhash, 0, 1))
  numY = Fix(sizeFlag / 9) + 1
  numX = (sizeFlag mod 9) + 1
  if len(blurhash) <> 4 + 2 * numX * numY
    print "blurhash length mismatch: length is " + Str(len(blurhash)) + " but it should be " + Str(4 + 2 * numX * numY)
    return false
  end if
  return true
end function

function sRGBToLinear(value as float)
  v = value / 255

  if v <= 0.04045
    return v / 12.92
  else
    return ((v + 0.055) / 1.055) ^ 2.4
  end if
end function

function decodeDC(value as integer)
  intR = value >> 16
  intG = (value >> 8) and 255
  intB = value and 255

  return [sRGBToLinear(intR), sRGBToLinear(intG), sRGBToLinear(intB)]

end function

function decodeAC(value as float, maximumValue as float)

  quantR = Fix(value / (19 * 19))
  quantG = Fix(value / 19) mod 19
  quantB = value mod 19

  rgb = [
    signPow((quantR - 9) / 9, 2.0) * maximumValue,
    signPow((quantG - 9) / 9, 2.0) * maximumValue,
    signPow((quantB - 9) / 9, 2.0) * maximumValue
  ]

  return rgb
end function


function signPow(val as float, exp as float)

  result = Abs(val)
  for i = 1 to exp step 1
    result = result * val
  end for

  return Sgn(val) * val ^ exp

end function

function linearTosRGB(value as float)

  v = value

  if value < 0
    v = 0
  else if value > 1
    v = 1
  end if

  if v <= 0.0031308
    return Cint(v * 12.92 * 255 + 0.5)
  else
    return Cint((1.055 * (v ^ (1 / 2.4)) - 0.055) * 255 + 0.5)
  end if
end function



function render(blurhash as string, width as integer, height as integer, punch = 1 as float)
  bhfn = CreateObject("roByteArray")
  bhfn.FromAsciiString(blurhash)
  digest = CreateObject("roEVPDigest")
  digest.Setup("md5")
  digest.Update(bhfn)
  fn = digest.Final()
  localFileSystem = CreateObject("roFileSystem")
  if localFileSystem.Exists("tmp://" + fn + ".bmp")
    return "tmp://" + fn + ".bmp"
  end if
  if isBlurhashValid(blurhash) = false then return invalid
  sizeFlag = decode83(Mid(blurhash, 1, 1))
  numY = Fix(sizeFlag / 9) + 1
  numX = (sizeFlag mod 9) + 1
  quantisedMaximumValue = decode83(Mid(blurhash, 2, 1))
  maximumValue = (quantisedMaximumValue + 1) / 166
  colors = []
  colorsLength = numX * numY
  for i = 0 to colorsLength - 1
    if i = 0
      value = decode83(Mid(blurhash, 3, 4))
      colors[i] = decodeDC(value)
    else
      value = decode83(Mid(blurhash, 5 + i * 2, 2))
      colors[i] = decodeAC(value, maximumValue * punch)
    end if
  end for
  pixels = CreateObject("roList")
  for i = 1 to numX * numY
    r = 0
    g = 0
    b = 0
    row = cint(i / numX)
    if i mod numX <> 0
      column = i mod numX
    else
      column = numX
    end if
    row_height = height / numY
    column_width = width / numX
    x = (column_width / 2) + (column_width * (column - 1))
    y = (row_height / 2) + (row_height * (row - 1))
    for j = 0 to numY - 1
      for n = 0 to numX - 1
        basis = cos((3.14159265 * x * n) / width) * cos((3.14159265 * y * j) / height)
        color = colors[n + j * numX]
        r = r + color[0] * basis
        g = g + color[1] * basis
        b = b + color[2] * basis
      end for
    end for
    pixel = [linearTosRGB(r), linearTosRGB(g), linearTosRGB(b)] ' our bitmap format wants bgr
    pixels.push(pixel)
  end for
  ba = simplebmp_bytearray(numX, numY, pixels)
  ba.WriteFile("tmp://" + fn + ".bmp")
  return "tmp://" + fn + ".bmp"
end function


