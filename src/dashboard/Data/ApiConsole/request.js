/*
 * Copyright (c) 2016-present, Parse, LLC
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */
export default function request(app, method, path, body, options) {
  const xhr = new XMLHttpRequest();
  if (path.startsWith('/') && app.serverURL.endsWith('/')) {
    path = path.substr(1);
  }
  if (!path.startsWith('/') && !app.serverURL.endsWith('/')) {
    path = '/' + path;
  }
  xhr.open(method, app.serverURL + path, true);
  xhr.setRequestHeader('Application-Id', app.applicationId);
  if (options.useMasterKey) {
    xhr.setRequestHeader('X-Parse-Master-Key', app.masterKey);
  } else if (app.restKey) {
    xhr.setRequestHeader('X-Parse-REST-API-Key', app.restKey);
  }

  // get date
  const date = new Date().toISOString();
  const key = '68FCmTWuWG570Iu9o6dVlbRYAPMqMU2kLO8FNLH7';

  // getHMAC_SHA1
  const hmac = getHMAC_SHA1(key, date);
  xhr.setRequestHeader('Date', date);
  xhr.setRequestHeader('Authorization', hmac);

  // set the date header
  if (options.sessionToken) {
    xhr.setRequestHeader('Session-Token', options.sessionToken);
  }
  return new Promise(resolve => {
    xhr.onload = function () {
      let response = xhr.responseText;
      try {
        response = JSON.parse(response);
      } catch (e) {
        /**/
      }
      resolve(response);
    };
    xhr.send(body);
  });

  function getHMAC_SHA1(key, date) {
    const hmac = crypto.createHmac('sha1', key);
    // log hmac
    hmac.update(date);

    console.log(hmac);
    const calculatedHMAC = hmac.digest('base64');
    return calculatedHMAC;
  }
}
