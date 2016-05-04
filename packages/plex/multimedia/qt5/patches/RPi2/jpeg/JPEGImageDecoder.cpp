/*
 * Copyright (C) 2006 Apple Computer, Inc.
 *
 * Portions are Copyright (C) 2001-6 mozilla.org
 *
 * Other contributors:
 *   Stuart Parmenter <stuart@mozilla.com>
 *
 * Copyright (C) 2007-2009 Torch Mobile, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

#include "config.h"
#include "platform/image-decoders/jpeg/JPEGImageDecoder.h"
#include "platform/PlatformInstrumentation.h"

#if CPU(BIG_ENDIAN) || CPU(MIDDLE_ENDIAN)
#error Blink assumes a little-endian target.
#endif

namespace {
  // JPEG only supports a denominator of 8.
  const unsigned scaleDenominator = 8;
}

namespace blink
{

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  JPEGImageDecoder::JPEGImageDecoder(AlphaOption alphaOption,
                                     GammaAndColorProfileOption gammaAndColorProfileOption,
                                     size_t maxDecodedBytes)
      : RPIImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes)
  {
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  JPEGImageDecoder::~JPEGImageDecoder()
  {
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  bool JPEGImageDecoder::setSize(unsigned width, unsigned height)
  {
    if (!ImageDecoder::setSize(width, height))
        return false;

    if (!desiredScaleNumerator())
        return setFailed();

    setDecodedSize(width, height);
    return true;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  void JPEGImageDecoder::setDecodedSize(unsigned width, unsigned height)
  {
    m_decodedSize = IntSize(width, height);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  unsigned JPEGImageDecoder::desiredScaleNumerator() const
  {
    size_t originalBytes = size().width() * size().height() * 4;
    if (originalBytes <= m_maxDecodedBytes) {
        return scaleDenominator;
    }

    // Downsample according to the maximum decoded size.
    unsigned scaleNumerator = static_cast<unsigned>(floor(sqrt(
    // MSVC needs explicit parameter type for sqrt().
    static_cast<float>(m_maxDecodedBytes * scaleDenominator * scaleDenominator / originalBytes))));

    return scaleNumerator;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  bool JPEGImageDecoder::readSize(unsigned int &width, unsigned int &height)
  {
    JFIFHEAD *header = (JFIFHEAD *)m_data->data();
    width = height = 0;

    if (m_data->size() >= (sizeof(*header) - JFIF_DATA_SIZE))
    {
      BYTE* dataptr = header->data;

      while (dataptr < ((BYTE*)header + m_data->size()))
      {
        if (dataptr[0] != 0xFF)
        {
          log("readJpegSize : got wrong marker %d", (int)dataptr[0]);
          return false;
        }

        // we look for size block marker
        if (dataptr[1] == 0xC0 && dataptr[2] == 0x0)
        {
          width = (dataptr[8] + dataptr[7] * 256);
          height = (dataptr[6] + dataptr[5] * 256);
          return true;
        }

        dataptr += dataptr[3] + (dataptr[2] * 256) + 2;
      }
    }
    else
    {
      log("readJpegSize : could not read %d bytes, read %d",sizeof(*header), m_data->size());
      return false;
    }


    log("readJpegSize : could not find the proper size marker in %d bytes", m_data->size());
    return false;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  void JPEGImageDecoder::decode(bool onlySize)
  {
    unsigned int width, height;

    if (failed())
        return;

    // make sure we have all the data before doing anything
    if (!isAllDataReceived())
        return;

    if (onlySize)
    {
      if (readSize(width, height));
      {
          setSize(width, height);
      }
      return;
    }
    else
    {
      readSize(width, height);

      ImageFrame& buffer = m_frameBufferCache[0];

      if (m_frameBufferCache.isEmpty())
      {
        log("decode : frameBuffercache is empty");
        setFailed();
        return;
      }

      if (buffer.status() == ImageFrame::FrameEmpty)
      {
        if (!buffer.setSize(width, height))
        {
            log("decode : could not define buffer size");
            setFailed();
            return;
        }

        // The buffer is transparent outside the decoded area while the image is
        // loading. The completed image will be marked fully opaque in jpegComplete().
        buffer.setHasAlpha(false);
      }

      decodeHW(m_data, buffer, width, height);
    }
  }
}
