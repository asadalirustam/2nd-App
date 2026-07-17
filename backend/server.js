require('dotenv').config();
const fs = require('fs');
const path = require('path');
const app = require('./src/app');

const connectDB = async () => {
  const conn = require('./src/config/db');
  await conn();
};

const updateFlutterConfig = (port) => {
  try {
    const constantsPath = path.join(__dirname, '..', 'lib', 'config', 'constants.dart');
    if (fs.existsSync(constantsPath)) {
      let content = fs.readFileSync(constantsPath, 'utf8');
      // Replace any port number inside the URLs (e.g. :5000/api or :5000)
      content = content.replace(/(http:\/\/localhost:)\d+(\/api)?/g, `$1${port}$2`);
      content = content.replace(/(http:\/\/10\.0\.2\.2:)\d+(\/api)?/g, `$1${port}$2`);
      fs.writeFileSync(constantsPath, content, 'utf8');
      console.log(`Successfully updated Flutter config constants.dart to use port ${port}`);
    }
  } catch (err) {
    console.error('Failed to update Flutter constants.dart:', err.message);
  }
};

const updateEnvFile = (port) => {
  try {
    const envPath = path.join(__dirname, '.env');
    if (fs.existsSync(envPath)) {
      let content = fs.readFileSync(envPath, 'utf8');
      if (content.includes('PORT=')) {
        content = content.replace(/PORT=\d+/g, `PORT=${port}`);
      } else {
        content = `PORT=${port}\n` + content;
      }
      fs.writeFileSync(envPath, content, 'utf8');
      console.log(`Successfully updated backend .env file to use port ${port}`);
    }
  } catch (err) {
    console.error('Failed to update .env:', err.message);
  }
};

const startServer = async () => {
  // Connect to database
  await connectDB();

  let PORT = parseInt(process.env.PORT || 5000, 10);

  const startListening = (port) => {
    const server = app.listen(port, () => {
      console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${port}`);
      updateFlutterConfig(port);
      updateEnvFile(port);
    });

    server.on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.log(`Port ${port} is in use, trying next port...`);
        startListening(port + 1);
      } else {
        console.error('Server error:', err);
      }
    });
  };

  startListening(PORT);

  // Handle unhandled promise rejections
  process.on('unhandledRejection', (err, promise) => {
    console.error(`Error: ${err.message}`);
  });
};

startServer();
