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
#include "RPIImageDecoder.h"
#include "platform/PlatformInstrumentation.h"

#if CPU(BIG_ENDIAN) || CPU(MIDDLE_ENDIAN)
#error Blink assumes a little-endian target.
#endif

namespace
{
  ///////////////////////////////////////////////////////////////////////////////////////////////////
  FILE *logFile=NULL;

  // decoding mutex : RPI HW decoder can only safely process one decode at a time
  pthread_mutex_t decode_mutex = PTHREAD_MUTEX_INITIALIZER;

} // namespace

namespace blink
{
  BRCMIMAGE_T* RPIImageDecoder::m_decoder=NULL;
  BRCMIMAGE_REQUEST_T RPIImageDecoder::m_dec_request;

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  RPIImageDecoder::RPIImageDecoder(AlphaOption alphaOption,
                                     GammaAndColorProfileOption gammaAndColorProfileOption,
                                     size_t maxDecodedBytes)
      : ImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes), m_hasAlpha(false)
  {
    if (!m_decoder)
    {
      BRCMIMAGE_STATUS_T status = brcmimage_create(BRCMIMAGE_TYPE_DECODER, MMAL_ENCODING_JPEG, &m_decoder);
      if (status != BRCMIMAGE_SUCCESS)
      {
          log("could not create HW JPEG decoder");
          brcmimage_release(m_decoder);
          m_decoder = NULL;
      }
      else
      {
          log("HW JPEG decoder created (%x)", m_decoder);
      }
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  void RPIImageDecoder::decodeHW(RefPtr<SharedBuffer> inputData, ImageFrame& outputBuffer, int outWidth, int outHeight)
  {
    clock_t start = clock();

    // lock the mutex so that we only process once at a time
    pthread_mutex_lock(&decode_mutex);

    // setup decoder request information
    BRCMIMAGE_REQUEST_T* dec_request = getDecoderRequest();
    BRCMIMAGE_T *decoder = getDecoder();

    memset(dec_request, 0, sizeof(BRCMIMAGE_REQUEST_T));
    dec_request->input = (unsigned char*)inputData->data();
    dec_request->input_size = inputData->size();
    dec_request->output = (unsigned char*)outputBuffer.getAddr(0, 0);
    dec_request->output_alloc_size = outWidth * outHeight * 4;
    dec_request->output_handle = 0;
    dec_request->pixel_format = PIXEL_FORMAT_RGBA;
    dec_request->buffer_width = 0;
    dec_request->buffer_height = 0;

    brcmimage_acquire(decoder);
    BRCMIMAGE_STATUS_T status = brcmimage_process(decoder, dec_request);

    if (status == BRCMIMAGE_SUCCESS)
    {
      clock_t copy = clock();

      unsigned char *ptr = (unsigned char *)outputBuffer.getAddr(0, 0);
      for (unsigned int i = 0; i < dec_request->height * dec_request->width; i++)
      {
        // we swap RGBA -> BGRA
        unsigned char tmp = *ptr;
        *ptr = ptr[2];
        ptr[2] = tmp;
        ptr += 4;
      }

      brcmimage_release(decoder);

      outputBuffer.setPixelsChanged(true);
      outputBuffer.setStatus(ImageFrame::FrameComplete);
      outputBuffer.setHasAlpha(m_hasAlpha);

      clock_t end = clock();
      unsigned long millis = (end - start) * 1000 / CLOCKS_PER_SEC;
      unsigned long copymillis = (end - copy) * 1000 / CLOCKS_PER_SEC;

      log("decode : image (%d x %d)(Alpha=%d) decoded in %d ms (copy in %d ms), source size = %d bytes", outWidth, outHeight, m_hasAlpha, millis, copymillis, inputData->size());

    }
    else
    {
      log("decode : Decoding failed with status %d", status);
    }

    pthread_mutex_unlock(&decode_mutex);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  void RPIImageDecoder::log(const char * format, ...)
  {
    if (!logFile)
    {
        logFile = fopen("/storage/webengine.log", "w");
    }

    va_list args;
    va_start (args, format);
    fprintf(logFile, "RPIImageDecoder(jpg):");
    vfprintf (logFile, format, args);
    fprintf(logFile, "\r\n");
    va_end (args);
    fflush(logFile);
  }
}
