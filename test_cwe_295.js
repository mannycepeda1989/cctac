const https = require('https');

function makeInsecureRequest() {
    // CWE-295 Trigger: rejectUnauthorized: false disables certificate validation
    const agent = new https.Agent({
        rejectUnauthorized: false
    });

    const options = {
        hostname: 'api.example.com',
        port: 443,
        path: '/v1/data',
        method: 'GET',
        agent: agent
    };

    const req = https.request(options, (res) => {
        console.log(`Status Code: ${res.statusCode}`);
        res.on('data', (d) => {
            process.stdout.write(d);
        });
    });

    req.on('error', (error) => {
        console.error(`Error: ${error.message}`);
    });

    req.end();
}

makeInsecureRequest();
