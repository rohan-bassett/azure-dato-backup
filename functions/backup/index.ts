import { AzureFunction, Context, HttpRequest } from '@azure/functions';

import { SiteClient } from 'datocms-client';
import fs from 'node:fs';
import path from 'node:path';
import { pipeline } from 'node:stream/promises';

const httpTrigger: AzureFunction = async (context: Context, req: HttpRequest): Promise<void> => {
  const client = new SiteClient(process.env.DATO_API_TOKEN);

  console.log('Downloading records...');

  let records = {};

  client.items
    .all({}, { allPages: true })
    .then((response) => {
      // fs.writeFileSync('./assets/records.json', JSON.stringify(response, null, 2));

      records = response;
    })
    .then(() => {
      return client.site.find();
    })
    .then((site) => {
      //   client.uploads.all({}, { allPages: true }).then(async (uploads) => {
      //     console.log({ length: uploads.length });
      //     fs.writeFileSync('./assets/assets.json', JSON.stringify(uploads, null, 2));
      //     return uploads.reduce((chain, upload) => {
      //       return chain.then(async () => {
      //         const imageUrl = 'https://' + site.imgixHost + upload.path;
      //         const fileExists = fs.existsSync('./assets/' + path.basename(upload.path));
      //         if (fileExists) {
      //           return;
      //         }
      //         // @ts-ignore
      //         const response = await fetch(imageUrl);
      //         const buffer = response.body;
      //         console.log('Downloading ' + imageUrl);
      //         // @ts-ignore
      //         await pipeline(buffer, fs.createWriteStream('./assets/' + path.basename(upload.path)));
      //       });
      //     }, Promise.resolve());
      //   });
    });

  console.log('Done!');

  context.res = {
    headers: {
      'content-type': 'application/json',
    },
    body: JSON.stringify(records),
  };
};

export default httpTrigger;
