const { Client } = require('pg');
require('dotenv').config();

async function setupDatabase() {
  const client = new Client({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'password',
    database: 'postgres' // Connect to default postgres database first
  });

  try {
    console.log('🔌 Connecting to PostgreSQL...');
    await client.connect();

    // Check if database exists
    const dbName = process.env.DB_NAME || 'giyas_ai_dev';
    const result = await client.query(
      "SELECT 1 FROM pg_database WHERE datname = $1",
      [dbName]
    );

    if (result.rows.length === 0) {
      console.log(`📦 Creating database: ${dbName}`);
      await client.query(`CREATE DATABASE "${dbName}"`);
      console.log(`✅ Database ${dbName} created successfully`);
    } else {
      console.log(`✅ Database ${dbName} already exists`);
    }

    // Create test database if needed
    const testDbName = process.env.DB_NAME_TEST || 'giyas_ai_test';
    const testResult = await client.query(
      "SELECT 1 FROM pg_database WHERE datname = $1",
      [testDbName]
    );

    if (testResult.rows.length === 0) {
      console.log(`📦 Creating test database: ${testDbName}`);
      await client.query(`CREATE DATABASE "${testDbName}"`);
      console.log(`✅ Test database ${testDbName} created successfully`);
    } else {
      console.log(`✅ Test database ${testDbName} already exists`);
    }

    console.log('🎉 Database setup completed successfully!');
    console.log('\n📋 Next steps:');
    console.log('1. Start the server: npm start');
    console.log('2. The server will automatically create tables');
    console.log('3. A demo user will be created: student@test.com / password123');

  } catch (error) {
    console.error('❌ Database setup failed:', error.message);
    console.log('\n💡 Troubleshooting:');
    console.log('1. Make sure PostgreSQL is running');
    console.log('2. Check your database credentials in .env file');
    console.log('3. Ensure the postgres user has permission to create databases');
  } finally {
    await client.end();
  }
}

// Run the setup
setupDatabase();
